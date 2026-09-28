import { Redirect, router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { ScrollView, Text, View } from 'react-native';

import { ErrorBanner, Field, Muted, PrimaryButton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { messageFrom, useAuth } from '@/src/store/auth';
import { colors, fonts } from '@/src/theme/colors';

export default function OtpScreen() {
  const { phone = '', needsName } = useLocalSearchParams<{ phone?: string; needsName?: string }>();
  const { isAuthenticated, initializing, verifyOtp } = useAuth();
  const [otp, setOtp] = useState('123456');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const needsDisplayName = needsName === '1';

  if (!initializing && isAuthenticated) return <Redirect href="/home" />;

  const verify = async () => {
    if (needsDisplayName && !name.trim()) {
      setError('Please enter your name');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await verifyOtp(String(phone), otp.trim(), name.trim() || undefined);
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 24 }}>
        <Text style={{ fontFamily: fonts.display, fontSize: 28, color: colors.ink }}>Enter the code</Text>
        <Muted>Sent to {phone}</Muted>
        <View style={{ height: 20 }} />
        <SoftPanel>
          <Field label="OTP" value={otp} onChangeText={setOtp} keyboardType="number-pad" />
          {needsDisplayName ? (
            <View style={{ marginTop: 14 }}>
              <Field label="Your name" placeholder="How coworkers should know you" value={name} onChangeText={setName} />
            </View>
          ) : null}
          <View style={{ height: 8 }} />
          <Muted>Dev tip: mock OTP is 123456</Muted>
          {error ? <View style={{ marginTop: 12 }}><ErrorBanner message={error} /></View> : null}
          <View style={{ height: 18 }} />
          <PrimaryButton label="Continue" loading={loading} onPress={verify} />
        </SoftPanel>
        <Text onPress={() => router.back()} style={{ color: colors.brandBlue, marginTop: 16, fontFamily: fonts.bodySemi }}>
          Back
        </Text>
      </ScrollView>
    </SkyScaffold>
  );
}
