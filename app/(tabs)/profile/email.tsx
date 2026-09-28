import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';

import { ErrorBanner, Field, Muted, OutlineButton, PrimaryButton, SectionLabel, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useInvalidateAll, useProfile } from '@/src/store/query';

export default function EmailScreen() {
  const profile = useProfile();
  const invalidate = useInvalidateAll();
  const [office, setOffice] = useState('');
  const [contact, setContact] = useState('');
  const [code, setCode] = useState('123456');
  const [pending, setPending] = useState(false);
  const [hint, setHint] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const verified = profile.data?.employeeVerified === true;

  useEffect(() => {
    if (!profile.data) return;
    setOffice(profile.data.officeEmail ?? '');
    setContact(profile.data.contactEmail ?? '');
    setPending(profile.data.officeEmailStatus === 'pending');
  }, [profile.data]);

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 16 }}>
        <Muted>
          Anyone can use Ride Buddy. Verifying a company email adds a Verified employee mark on your posts. Personal mail is optional.
        </Muted>
        <SectionLabel>Office email</SectionLabel>
        <SoftPanel>
          {verified ? (
            <>
              <Muted>Verified employee{'\n'}{profile.data?.officeEmail}</Muted>
              <View style={{ height: 12 }} />
              <OutlineButton
                danger
                label="Remove verification"
                onPress={async () => {
                  setBusy(true);
                  try {
                    await rideRepo.clearOfficeEmail();
                    invalidate();
                    setPending(false);
                    setOffice('');
                  } catch (e) {
                    setError(messageFrom(e));
                  } finally {
                    setBusy(false);
                  }
                }}
              />
            </>
          ) : (
            <>
              <Field label="Company email" placeholder="you@company.com" autoCapitalize="none" keyboardType="email-address" value={office} onChangeText={setOffice} />
              <View style={{ height: 12 }} />
              <PrimaryButton
                label={pending ? 'Resend code' : 'Send verification code'}
                loading={busy}
                onPress={async () => {
                  setBusy(true);
                  try {
                    const res = await rideRepo.requestOfficeEmail(office.trim());
                    invalidate();
                    setPending(true);
                    setHint(String(res.hint ?? 'Email service not wired yet — use the mock code.'));
                  } catch (e) {
                    setError(messageFrom(e));
                  } finally {
                    setBusy(false);
                  }
                }}
              />
              {pending ? (
                <>
                  <View style={{ height: 14 }} />
                  <Field label="Verification code" value={code} onChangeText={setCode} keyboardType="number-pad" />
                  <View style={{ height: 12 }} />
                  <PrimaryButton
                    label="Verify office email"
                    loading={busy}
                    onPress={async () => {
                      setBusy(true);
                      try {
                        await rideRepo.verifyOfficeEmail(code.trim());
                        invalidate();
                        Alert.alert('Verified employee');
                        router.back();
                      } catch (e) {
                        setError(messageFrom(e));
                      } finally {
                        setBusy(false);
                      }
                    }}
                  />
                </>
              ) : null}
              {hint ? <View style={{ marginTop: 8 }}><Muted>{hint}</Muted></View> : null}
              <View style={{ height: 8 }} />
              <Muted>Mail sending is a placeholder — use mock code 123456 in local/dev.</Muted>
            </>
          )}
        </SoftPanel>
        <SectionLabel>Personal / social email</SectionLabel>
        <SoftPanel>
          <Muted>Optional. Gmail, Outlook, etc. — join and contact only, not for employee verification.</Muted>
          <View style={{ height: 12 }} />
          <Field label="Personal email" placeholder="you@gmail.com" autoCapitalize="none" keyboardType="email-address" value={contact} onChangeText={setContact} />
          <View style={{ height: 12 }} />
          <OutlineButton
            label="Save personal email"
            onPress={async () => {
              setBusy(true);
              try {
                await rideRepo.updateProfile({ contactEmail: contact.trim() });
                invalidate();
                Alert.alert('Saved', 'Personal email saved');
              } catch (e) {
                setError(messageFrom(e));
              } finally {
                setBusy(false);
              }
            }}
          />
        </SoftPanel>
        {error ? <ErrorBanner message={error} /> : null}
      </ScrollView>
    </SkyScaffold>
  );
}
