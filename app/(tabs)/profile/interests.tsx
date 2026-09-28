import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';

import { ErrorBanner, Muted, PrimaryButton, SectionLabel, SkyScaffold } from '@/src/components/ui/kit';
import { interestGroups } from '@/src/data/interestGroups';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useInvalidateAll, useProfile } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

export default function InterestsScreen() {
  const profile = useProfile();
  const invalidate = useInvalidateAll();
  const [selected, setSelected] = useState<string[]>([]);
  const [top, setTop] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!profile.data) return;
    setSelected(profile.data.interests);
    setTop(profile.data.topInterests.slice(0, 5));
  }, [profile.data]);

  const toggle = (tag: string) => {
    setSelected((cur) => {
      if (cur.includes(tag)) {
        setTop((t) => t.filter((x) => x !== tag));
        return cur.filter((x) => x !== tag);
      }
      if (cur.length >= 30) return cur;
      const next = [...cur, tag];
      setTop((t) => (t.length < 5 ? [...t, tag] : t));
      return next;
    });
  };

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
        <Muted>Add at least 5. Tap again on selected tags to set your top 5 for posts.</Muted>
        {Object.entries(interestGroups).map(([group, tags]) => (
          <View key={group} style={{ marginTop: 18 }}>
            <SectionLabel>{group}</SectionLabel>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
              {tags.map((tag) => {
                const on = selected.includes(tag);
                const isTop = top.includes(tag);
                return (
                  <Pressable
                    key={tag}
                    onPress={() => toggle(tag)}
                    onLongPress={() => {
                      if (!on) return;
                      setTop((t) => (t.includes(tag) ? t.filter((x) => x !== tag) : t.length < 5 ? [...t, tag] : t));
                    }}
                    style={{
                      paddingHorizontal: 10,
                      paddingVertical: 7,
                      borderRadius: 10,
                      borderWidth: 1,
                      borderColor: isTop ? colors.brandOrange : colors.line,
                      backgroundColor: on ? `${colors.brandOrange}2E` : colors.skyMid,
                    }}>
                    <Text style={{ fontFamily: fonts.bodySemi, color: isTop ? colors.brandOrange : colors.ink }}>
                      {isTop ? `★ ${tag}` : tag}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
          </View>
        ))}
        {error ? <View style={{ marginTop: 12 }}><ErrorBanner message={error} /></View> : null}
        <View style={{ height: 18 }} />
        <PrimaryButton
          label={`Save (${selected.length} selected)`}
          loading={saving}
          onPress={async () => {
            if (selected.length < 5) {
              setError('Add at least 5 interests');
              return;
            }
            setSaving(true);
            try {
              await rideRepo.updateInterests(selected, top.slice(0, 5));
              invalidate();
              router.back();
            } catch (e) {
              setError(messageFrom(e));
            } finally {
              setSaving(false);
            }
          }}
        />
      </ScrollView>
    </SkyScaffold>
  );
}
