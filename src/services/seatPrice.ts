export type BackSeatMode = 'spacious2' | 'standard3';

export type SeatPriceEstimate = {
  suggestedPerSeat: number;
  distanceKm: number;
  durationMinutes: number;
  seats: number;
  totalRunningCost: number;
  peak: boolean;
  backSeatMode: BackSeatMode;
  summary: string;
};

const rupeesPerKm = 7.5;
const baseFee = 25;
const minPerSeat = 20;
const maxPerSeat = 250;

export function backSeats(mode: BackSeatMode): number {
  return mode === 'spacious2' ? 2 : 3;
}

export function canOfferThreeBack(vehicleTotalSeats: number): boolean {
  return vehicleTotalSeats - 1 >= 3;
}

export function maxBackSeatsFor(vehicleTotalSeats: number, mode: BackSeatMode): number {
  const passengerCap = Math.min(8, Math.max(1, vehicleTotalSeats - 1));
  return Math.min(passengerCap, Math.max(1, backSeats(mode)));
}

function isPeak(depart: Date): boolean {
  const h = depart.getHours();
  return (h >= 7 && h < 11) || (h >= 17 && h < 21);
}

function roundToFive(value: number): number {
  if (value <= 0) return minPerSeat;
  return Math.round(value / 5) * 5;
}

export function estimateSeatPrice(opts: {
  distanceMeters: number;
  durationSeconds: number;
  seats: number;
  departAt: Date;
  backSeatMode: BackSeatMode;
}): SeatPriceEstimate {
  const seatCount = Math.min(8, Math.max(1, opts.seats));
  const km = Math.min(100, Math.max(0.5, opts.distanceMeters / 1000));
  const mins = Math.min(240, Math.max(1, Math.round(opts.durationSeconds / 60)));
  const peak = isPeak(opts.departAt);
  const expectedMins = Math.min(240, Math.max(1, Math.round(km * 2.2)));
  const congestionExtra = mins > expectedMins ? (mins - expectedMins) * 0.6 : 0;
  let total = baseFee + km * rupeesPerKm + congestionExtra;
  if (peak) total *= 1.12;
  if (opts.backSeatMode === 'spacious2') total = total * 1.18 + 35;
  else total *= 0.97;
  const suggested = Math.min(maxPerSeat, Math.max(minPerSeat, roundToFive(total / seatCount)));
  const parts = [
    `${km >= 10 ? km.toFixed(0) : km.toFixed(1)} km`,
    `${backSeats(opts.backSeatMode)} back · ${seatCount} offered`,
    peak ? 'peak hour' : null,
    opts.backSeatMode === 'spacious2' ? 'spacious' : null,
  ].filter(Boolean);
  return {
    suggestedPerSeat: suggested,
    distanceKm: km,
    durationMinutes: mins,
    seats: seatCount,
    totalRunningCost: total,
    peak,
    backSeatMode: opts.backSeatMode,
    summary: `Suggested ₹${suggested} · ${parts.join(' · ')}`,
  };
}
