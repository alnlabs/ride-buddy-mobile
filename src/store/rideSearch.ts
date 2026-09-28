import { PlaceSuggestion } from '@/src/models/types';

export type RideSearchDraft = {
  from: PlaceSuggestion;
  to: PlaceSuggestion;
  when: Date;
};

let draft: RideSearchDraft | null = null;

export function setRideSearchDraft(next: RideSearchDraft) {
  draft = next;
}

export function takeRideSearchDraft(): RideSearchDraft | null {
  const current = draft;
  draft = null;
  return current;
}
