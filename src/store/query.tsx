import { QueryClient, QueryClientProvider, useQuery, useQueryClient } from '@tanstack/react-query';
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

import { Profile } from '@/src/models/types';
import { chatRepo } from '@/src/services/chatRepository';
import { rideRepo } from '@/src/services/rideRepository';
import { useAuth } from '@/src/store/auth';

const client = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 15_000 } },
});

export function QueryProvider({ children }: { children: ReactNode }) {
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
}

export function useProfile() {
  const { userId, isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ['profile', userId],
    queryFn: () => rideRepo.getProfile(),
    enabled: isAuthenticated && Boolean(userId),
  });
}

export function useVehicles() {
  const { userId, isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ['vehicles', userId],
    queryFn: () => rideRepo.vehicles(),
    enabled: isAuthenticated,
  });
}

export function useMyTrips() {
  const { userId, isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ['trips', userId],
    queryFn: () => rideRepo.myBookings(),
    enabled: isAuthenticated,
  });
}

export function useChatInbox() {
  const { userId, isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ['chatInbox', userId],
    queryFn: () => chatRepo.conversations(),
    enabled: isAuthenticated,
  });
}

export function useSeatRequestCount() {
  const { userId, isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ['seatRequests', userId],
    queryFn: async () => {
      try {
        return (await rideRepo.needsInbox()).length;
      } catch {
        return 0;
      }
    },
    enabled: isAuthenticated,
  });
}

const RideRevContext = createContext<{ revision: number; bump: () => void }>({
  revision: 0,
  bump: () => undefined,
});

export function RideRevisionProvider({ children }: { children: ReactNode }) {
  const [revision, setRevision] = useState(0);
  const value = useMemo(() => ({ revision, bump: () => setRevision((v) => v + 1) }), [revision]);
  return <RideRevContext.Provider value={value}>{children}</RideRevContext.Provider>;
}

export function useRideRevision() {
  return useContext(RideRevContext);
}

export function useInvalidateAll() {
  const qc = useQueryClient();
  return () => {
    void qc.invalidateQueries();
  };
}

export type { Profile };
