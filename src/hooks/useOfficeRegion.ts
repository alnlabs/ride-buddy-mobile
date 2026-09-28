import { useQuery } from '@tanstack/react-query';

import { PlaceSuggestion } from '@/src/models/types';
import { reverseDetailed } from '@/src/services/nominatim';
import { shortenStoredLabel } from '@/src/services/placeLabel';
import { useAuth } from '@/src/store/auth';
import { useProfile } from '@/src/store/query';

export type OfficeMapRegion = {
  lat: number;
  lng: number;
  city?: string | null;
  home?: PlaceSuggestion | null;
  office?: PlaceSuggestion | null;
};

const HYDERABAD: OfficeMapRegion = { lat: 17.385, lng: 78.4867, city: 'Hyderabad' };

export function useOfficeRegion() {
  const { userId } = useAuth();
  const profile = useProfile();
  return useQuery({
    queryKey: ['officeRegion', userId, profile.data?.officeLat, profile.data?.homeLat],
    enabled: profile.isSuccess || profile.isError,
    queryFn: async (): Promise<OfficeMapRegion> => {
      const p = profile.data;
      if (p?.officeLat != null && p.officeLng != null) {
        const officeDetailed = await reverseDetailed(p.officeLat, p.officeLng);
        let home: PlaceSuggestion | undefined;
        if (p.homeLat != null && p.homeLng != null) {
          const homeDetailed = await reverseDetailed(p.homeLat, p.homeLng);
          home = {
            publicShort: homeDetailed?.publicShort ?? shortenStoredLabel(p.homeLabel ?? 'Home'),
            fullAddress: homeDetailed?.fullAddress ?? p.homeLabel,
            privateLabel: p.homeLabel?.trim() || 'Home',
            lat: p.homeLat,
            lng: p.homeLng,
            kind: 'home',
          };
        }
        return {
          lat: p.officeLat,
          lng: p.officeLng,
          city: officeDetailed?.city ?? p.officeLabel?.split(',').at(-2)?.trim(),
          office: {
            publicShort: officeDetailed?.publicShort ?? shortenStoredLabel(p.officeLabel ?? 'Office'),
            fullAddress: officeDetailed?.fullAddress ?? p.officeLabel,
            privateLabel: p.officeLabel?.trim() || 'Office',
            lat: p.officeLat,
            lng: p.officeLng,
            city: officeDetailed?.city,
            kind: 'office',
          },
          home,
        };
      }
      return HYDERABAD;
    },
  });
}
