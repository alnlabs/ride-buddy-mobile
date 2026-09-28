import { MaterialIcons } from '@expo/vector-icons';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { PlaceSuggestion, placeFieldLabel } from '@/src/models/types';
import { searchPlaces } from '@/src/services/nominatim';
import { colors, fonts } from '@/src/theme/colors';

type Props = {
  label: string;
  value?: PlaceSuggestion | null;
  initialText?: string;
  searchCity?: string | null;
  nearLat?: number | null;
  nearLng?: number | null;
  onSelected: (place: PlaceSuggestion) => void;
  onMyLocation?: () => Promise<PlaceSuggestion | null>;
};

export function PlaceSearchField({
  label,
  value,
  initialText,
  searchCity,
  nearLat,
  nearLng,
  onSelected,
  onMyLocation,
}: Props) {
  const [query, setQuery] = useState(initialText ?? (value ? placeFieldLabel(value) : ''));
  const [results, setResults] = useState<PlaceSuggestion[]>([]);
  const [loading, setLoading] = useState(false);
  const [locating, setLocating] = useState(false);

  useEffect(() => {
    if (value) setQuery(placeFieldLabel(value));
  }, [value]);

  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) {
      setResults([]);
      return;
    }
    if (value && placeFieldLabel(value) === q) {
      setResults([]);
      return;
    }
    const handle = setTimeout(async () => {
      setLoading(true);
      try {
        setResults(await searchPlaces(q, { city: searchCity, nearLat, nearLng }));
      } finally {
        setLoading(false);
      }
    }, 350);
    return () => clearTimeout(handle);
  }, [query, searchCity, nearLat, nearLng, value]);

  return (
    <View style={styles.wrap}>
      <Text style={styles.label}>{label}</Text>
      <View style={styles.row}>
        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Search an area or landmark"
          placeholderTextColor={colors.inkMuted}
          style={styles.input}
        />
        {onMyLocation ? (
          <Pressable
            onPress={async () => {
              setLocating(true);
              try {
                const place = await onMyLocation();
                if (place) {
                  setQuery(placeFieldLabel(place));
                  onSelected(place);
                }
              } finally {
                setLocating(false);
              }
            }}
            style={styles.locBtn}>
            {locating ? <ActivityIndicator size="small" color={colors.brandBlue} /> : <MaterialIcons name="my-location" size={20} color={colors.brandBlue} />}
          </Pressable>
        ) : null}
      </View>
      {loading ? <ActivityIndicator style={{ marginTop: 8 }} color={colors.brandBlue} /> : null}
      {results.map((p) => (
        <Pressable
          key={`${p.lat}-${p.lng}-${p.publicShort}`}
          onPress={() => {
            setQuery(placeFieldLabel(p));
            setResults([]);
            onSelected(p);
          }}
          style={styles.hit}>
          <MaterialIcons name="place" size={18} color={colors.brandOrange} />
          <View style={{ flex: 1 }}>
            <Text style={styles.hitTitle}>{p.publicShort}</Text>
            {p.fullAddress ? <Text style={styles.hitSub} numberOfLines={1}>{p.fullAddress}</Text> : null}
          </View>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { backgroundColor: colors.surfaceElevated, borderRadius: 16, borderWidth: 1, borderColor: colors.line, padding: 12 },
  label: { fontFamily: fonts.bodySemi, color: colors.inkMuted, marginBottom: 6 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  input: { flex: 1, fontFamily: fonts.body, fontSize: 16, color: colors.ink, paddingVertical: 8 },
  locBtn: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  hit: { flexDirection: 'row', gap: 8, alignItems: 'center', paddingVertical: 10, borderTopWidth: 1, borderTopColor: colors.line },
  hitTitle: { fontFamily: fonts.bodySemi, color: colors.ink },
  hitSub: { fontFamily: fonts.body, color: colors.inkMuted, fontSize: 12 },
});
