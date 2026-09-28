import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { ScrollView, View } from 'react-native';

import { ErrorBanner, Field, Muted, PrimaryButton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useInvalidateAll, useProfile } from '@/src/store/query';

export default function WorkScreen() {
  const profile = useProfile();
  const invalidate = useInvalidateAll();
  const [role, setRole] = useState('');
  const [company, setCompany] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (profile.data) {
      setRole(profile.data.jobRole ?? '');
      setCompany(profile.data.company ?? '');
    }
  }, [profile.data]);

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 16 }}>
        <Muted>Shown on every ride or need you post, so others know who they’re riding with.</Muted>
        <SoftPanel>
          <Field label="Role" placeholder="e.g. Product Designer" value={role} onChangeText={setRole} />
          <View style={{ height: 12 }} />
          <Field label="Company" placeholder="e.g. Acme Labs" value={company} onChangeText={setCompany} />
        </SoftPanel>
        {error ? <ErrorBanner message={error} /> : null}
        <PrimaryButton
          label="Save"
          loading={saving}
          onPress={async () => {
            if (!role.trim() || !company.trim()) {
              setError('Add both your role and company — they appear on every post');
              return;
            }
            setSaving(true);
            try {
              await rideRepo.updateProfile({ jobRole: role.trim(), company: company.trim() });
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
