import { Redirect, router } from 'expo-router';
import { useState } from 'react';
import { Image, KeyboardAvoidingView, Platform, ScrollView, Text, View } from 'react-native';

import { BrandWordmark, ErrorBanner, Field, Muted, PrimaryButton, SkyScaffold, SoftPanel } from '@/src/components/ui/kit';
import { messageFrom, useAuth } from '@/src/store/auth';
import { colors, fonts } from '@/src/theme/colors';

export default function LoginScreen() {
  const { isAuthenticated, initializing, requestOtp } = useAuth();
  const [phone, setPhone] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!initializing && isAuthenticated) return <Redirect href="/home" />;

  const submit = async () => {
    setLoading(true);
    setError(null);
    try {
      const needsName = await requestOtp(phone.trim());
      router.push({ pathname: '/otp', params: { phone: phone.trim(), needsName: needsName ? '1' : '0' } });
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <SkyScaffold>
      <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={{ padding: 24, flexGrow: 1, justifyContent: 'center' }}>
          <View style={{ alignItems: 'center', marginBottom: 32 }}>
            <Image source={require('../assets/logos/app_icon.png')} style={{ width: 108, height: 108 }} />
            <BrandWordmark fontSize={38} center />
            <Muted center>Employee carpool made simple</Muted>
          </View>
          <SoftPanel>
            <Text style={{ fontFamily: fonts.displaySemi, fontSize: 22, color: colors.ink }}>Sign in</Text>
            <Muted>We’ll send a one-time code to your phone</Muted>
            <View style={{ height: 16 }} />
            <Field
              label="Phone number"
              placeholder="9876543210"
              keyboardType="phone-pad"
              value={phone}
              onChangeText={setPhone}
              onSubmitEditing={submit}
            />
            {error ? <View style={{ marginTop: 12 }}><ErrorBanner message={error} /></View> : null}
            <View style={{ height: 18 }} />
            <PrimaryButton label="Send OTP" loading={loading} onPress={submit} />
          </SoftPanel>
          <View style={{ height: 20 }} />
          <Muted center>By continuing you agree to use Ride Buddy for office commuting.</Muted>
        </ScrollView>
      </KeyboardAvoidingView>
    </SkyScaffold>
  );
}
