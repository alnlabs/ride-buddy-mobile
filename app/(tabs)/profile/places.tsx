import { useCallback, useEffect, useState } from 'react';
import { Alert, Modal, Pressable, ScrollView, Text, View } from 'react-native';

import { OsmMap } from '@/src/components/maps/OsmMap';
import { PlaceSearchField } from '@/src/components/maps/PlaceSearchField';
import { EmptyState, ErrorBanner, Field, OutlineButton, PrimaryButton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { FilterChip } from '@/src/components/v2/primitives';
import { useOfficeRegion } from '@/src/hooks/useOfficeRegion';
import { PlaceSuggestion, SavedPlace } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useInvalidateAll } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

const KINDS = [
  { id: 'home', label: 'Home' },
  { id: 'office', label: 'Office' },
  { id: 'home', label: "Parents' Home" },
  { id: 'home', label: 'Weekend Home' },
  { id: 'office', label: 'Main Office' },
  { id: 'office', label: 'Client Office' },
  { id: 'home', label: 'Gym' },
  { id: 'home', label: 'College' },
  { id: 'home', label: 'Airport' },
  { id: 'home', label: 'Custom Place' },
];

export default function PlacesScreen() {
  const region = useOfficeRegion();
  const invalidate = useInvalidateAll();
  const [places, setPlaces] = useState<SavedPlace[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [editor, setEditor] = useState<{ kind: string; existing?: SavedPlace } | null>(null);
  const [draft, setDraft] = useState<PlaceSuggestion | null>(null);
  const [label, setLabel] = useState('');

  const load = useCallback(async () => {
    try {
      setPlaces(await rideRepo.savedPlaces());
    } catch (e) {
      setError(messageFrom(e));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const save = async () => {
    if (!editor || !draft) return;
    const kindLabel = KINDS.find((k) => k.id === editor.kind)?.label ?? 'Place';
    const body = {
      kind: editor.kind,
      privateLabel: label.trim() || kindLabel,
      publicShort: draft.publicShort,
      fullAddress: draft.fullAddress,
      lat: draft.lat,
      lng: draft.lng,
      primary: !places.some((p) => p.kind === editor.kind && p.primary),
    };
    try {
      if (editor.existing) await rideRepo.updateSavedPlace(editor.existing.id, body);
      else await rideRepo.createSavedPlace(body);
      invalidate();
      setEditor(null);
      await load();
    } catch (e) {
      setError(messageFrom(e));
    }
  };

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        {error ? <ErrorBanner message={error} /> : null}
        <Text style={{ fontFamily: fonts.body, color: colors.inkMuted }}>
          Exact addresses stay private. Rides use an approximate public pickup.
        </Text>
        <OsmMap
          height={180}
          center={{ latitude: region.data?.lat ?? 17.385, longitude: region.data?.lng ?? 78.4867 }}
          points={places.map((p) => ({ latitude: p.lat, longitude: p.lng, title: p.privateLabel }))}
        />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 8 }}>
          {KINDS.map((k) => (
            <FilterChip key={k.label} label={k.label} onPress={() => { setEditor({ kind: k.id }); setDraft(null); setLabel(k.label); }} />
          ))}
        </ScrollView>
        {places.length === 0 ? (
          <SoftPanel>
            <EmptyState title="No saved places" subtitle="Add Home and Office to personalize Home" icon="place" />
          </SoftPanel>
        ) : (
          places.map((p) => (
            <SoftPanel key={p.id}>
              <Text style={{ fontFamily: fonts.displaySemi }}>{p.privateLabel}{p.primary ? ' · Primary' : ''}</Text>
              <Text style={{ color: colors.inkMuted }}>{p.publicShort}</Text>
              <View style={{ flexDirection: 'row', gap: 16, marginTop: 10 }}>
                {!p.primary ? (
                  <Pressable onPress={async () => { await rideRepo.setPrimarySavedPlace(p.id); invalidate(); await load(); }}>
                    <Text style={{ color: colors.brandBlue, fontFamily: fonts.bodySemi }}>Make primary</Text>
                  </Pressable>
                ) : null}
                <Pressable onPress={() => { setEditor({ kind: p.kind, existing: p }); setDraft({ publicShort: p.publicShort, fullAddress: p.fullAddress, lat: p.lat, lng: p.lng, privateLabel: p.privateLabel, kind: p.kind }); setLabel(p.privateLabel); }}>
                  <Text style={{ color: colors.brandBlue, fontFamily: fonts.bodySemi }}>Edit</Text>
                </Pressable>
                <Pressable onPress={() => Alert.alert('Remove place?', `Remove “${p.privateLabel}”?`, [
                  { text: 'Cancel' },
                  { text: 'Remove', style: 'destructive', onPress: async () => { await rideRepo.deleteSavedPlace(p.id); invalidate(); await load(); } },
                ])}>
                  <Text style={{ color: colors.danger, fontFamily: fonts.bodySemi }}>Remove</Text>
                </Pressable>
              </View>
            </SoftPanel>
          ))
        )}
      </ScrollView>
      <Modal visible={!!editor} animationType="slide" onRequestClose={() => setEditor(null)}>
        <SkyScaffold>
          <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
            <Text style={{ fontFamily: fonts.displaySemi, fontSize: 22 }}>
              {editor?.existing ? 'Edit place' : `Add ${KINDS.find((k) => k.id === editor?.kind)?.label ?? 'place'}`}
            </Text>
            <Field label="Private label" value={label} onChangeText={setLabel} />
            <PlaceSearchField
              label="Search address"
              value={draft}
              searchCity={region.data?.city}
              nearLat={region.data?.lat}
              nearLng={region.data?.lng}
              onSelected={setDraft}
            />
            <PrimaryButton label="Save place" onPress={save} />
            <OutlineButton label="Close" onPress={() => setEditor(null)} />
          </ScrollView>
        </SkyScaffold>
      </Modal>
    </SkyScaffold>
  );
}
