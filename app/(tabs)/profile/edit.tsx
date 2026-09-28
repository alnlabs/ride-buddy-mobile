import { router } from 'expo-router';
import { ScrollView, View } from 'react-native';

import { ActionRow, ErrorView, LoadingSkeleton, SectionLabel, SkyScaffold, SoftPanel, StrengthBar } from '@/src/components/ui/kit';
import { emailSetupSubtitle, profileWorkLine } from '@/src/models/types';
import { useProfile } from '@/src/store/query';
import { colors } from '@/src/theme/colors';

export default function EditProfileScreen() {
  const profile = useProfile();
  if (profile.isLoading) return <SkyScaffold><LoadingSkeleton /></SkyScaffold>;
  if (!profile.data) return <SkyScaffold><ErrorView message="Couldn’t load profile" onRetry={() => profile.refetch()} /></SkyScaffold>;
  const p = profile.data;

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20 }}>
        <SoftPanel>
          <StrengthBar value={p.profileStrength} />
        </SoftPanel>
        <View style={{ height: 22 }} />
        <SectionLabel>Setup</SectionLabel>
        <View style={{ height: 10 }} />
        <ActionRow icon="mark-email-read" title="Email" subtitle={emailSetupSubtitle(p)} onPress={() => router.push('/profile/email')} />
        <View style={{ height: 10 }} />
        <ActionRow icon="badge" title="Role & company" subtitle={p.jobRole ? profileWorkLine(p)! : 'Shown on every ride or need post'} onPress={() => router.push('/profile/work')} />
        <View style={{ height: 10 }} />
        <ActionRow icon="place" title="Home & Office" subtitle={p.homeLat && p.officeLat ? 'Saved for commute matching' : 'Add places to match better'} accent={colors.brandOrange} onPress={() => router.push('/profile/places')} />
        <View style={{ height: 10 }} />
        <ActionRow
          icon="interests"
          title="Interests"
          subtitle={p.topInterests.length ? `On posts: ${p.topInterests.slice(0, 5).join(', ')}` : 'Add at least 5 · pick top 5 for posts'}
          onPress={() => router.push('/profile/interests')}
        />
      </ScrollView>
    </SkyScaffold>
  );
}
