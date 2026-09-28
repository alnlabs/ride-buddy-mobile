import { router } from 'expo-router';
import { ScrollView, Text, View } from 'react-native';

import {
  Avatar,
  ErrorView,
  LoadingSkeleton,
  PrimaryButton,
  SectionLabel,
  SkyScaffold,
  SoftPanel,
  StrengthBar,
} from '@/src/components/ui/kit';
import { emailSetupSubtitle, profileWorkLine } from '@/src/models/types';
import { useAuth } from '@/src/store/auth';
import { useProfile } from '@/src/store/query';
import { colors, fonts } from '@/src/theme/colors';

function Info({ title, body }: { title: string; body: string }) {
  return (
    <SoftPanel>
      <Text style={{ fontFamily: fonts.bodySemi, color: colors.ink }}>{title}</Text>
      <Text style={{ fontFamily: fonts.body, color: colors.inkMuted, marginTop: 4 }}>{body}</Text>
    </SoftPanel>
  );
}

export default function ProfileViewScreen() {
  const { phone } = useAuth();
  const profile = useProfile();
  if (profile.isLoading) return <SkyScaffold><LoadingSkeleton /></SkyScaffold>;
  if (!profile.data) return <SkyScaffold><ErrorView message="Couldn’t load profile" onRetry={() => profile.refetch()} /></SkyScaffold>;
  const p = profile.data;

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12 }}>
        <SoftPanel>
          <View style={{ flexDirection: 'row', gap: 14 }}>
            <Avatar name={p.displayName} size={60} />
            <View style={{ flex: 1 }}>
              <Text style={{ fontFamily: fonts.displaySemi, fontSize: 20 }}>{p.displayName}</Text>
              {p.employeeVerified ? <Text style={{ color: colors.brandBlue }}>Verified employee</Text> : null}
              {profileWorkLine(p) ? <Text>{profileWorkLine(p)}</Text> : null}
              {phone ? <Text style={{ color: colors.inkMuted }}>{phone}</Text> : null}
            </View>
          </View>
          <View style={{ height: 14 }} />
          <StrengthBar value={p.profileStrength} />
        </SoftPanel>
        <SectionLabel>Work</SectionLabel>
        <Info title="Role & company" body={profileWorkLine(p) ?? 'Not added yet'} />
        <Info title="Email status" body={emailSetupSubtitle(p)} />
        <SectionLabel>Places</SectionLabel>
        <Info title="Home" body={p.homeLabel ?? 'Not added yet'} />
        <Info title="Office" body={p.officeLabel ?? 'Not added yet'} />
        <SectionLabel>Interests</SectionLabel>
        <Info
          title="Top interests"
          body={p.topInterests.length ? p.topInterests.join(', ') : p.interests.slice(0, 5).join(', ') || 'Not added yet'}
        />
        <PrimaryButton label="Edit profile" icon="edit" onPress={() => router.push('/profile/edit')} />
      </ScrollView>
    </SkyScaffold>
  );
}
