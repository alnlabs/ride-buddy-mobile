import { useState } from 'react';
import { Alert, Modal, ScrollView, Text, View } from 'react-native';

import {
  EmptyState,
  ErrorBanner,
  ErrorView,
  Field,
  LoadingSkeleton,
  OutlineButton,
  PrimaryButton,
  SkyScaffold,
  SoftPanel,
} from '@/src/components/ui/kit';
import { CarCatalogFields, type CarSelection } from '@/src/components/vehicle/CarCatalogFields';
import { CarModelIcon } from '@/src/components/vehicle/CarModelIcon';
import { Vehicle, vehicleDisplayName } from '@/src/models/types';
import { rideRepo } from '@/src/services/rideRepository';
import { messageFrom } from '@/src/store/auth';
import { useInvalidateAll, useVehicles } from '@/src/store/query';
import { colors, fonts, weights } from '@/src/theme/colors';

export default function VehiclesScreen() {
  const vehicles = useVehicles();
  const invalidate = useInvalidateAll();
  const [open, setOpen] = useState(false);
  const [nick, setNick] = useState('');
  const [picked, setPicked] = useState<CarSelection | null>(null);
  const [formKey, setFormKey] = useState(0);
  const [plate, setPlate] = useState('');
  const [seats, setSeats] = useState('5');
  const [color, setColor] = useState('White');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  if (vehicles.isLoading) {
    return (
      <SkyScaffold>
        <LoadingSkeleton />
      </SkyScaffold>
    );
  }
  if (vehicles.isError) {
    return (
      <SkyScaffold>
        <ErrorView message={messageFrom(vehicles.error)} onRetry={() => vehicles.refetch()} />
      </SkyScaffold>
    );
  }
  const list = vehicles.data ?? [];

  const resetForm = () => {
    setNick('');
    setPicked(null);
    setFormKey((k) => k + 1);
    setPlate('');
    setSeats('5');
    setColor('White');
    setError(null);
  };

  const save = async () => {
    if (!picked?.makeModel || !plate.trim()) {
      setError('Choose a car and enter the plate number');
      return;
    }
    const seatCount = Number(seats);
    if (seatCount < 2 || seatCount > 8) {
      setError('Seats must be between 2 and 8');
      return;
    }
    setSaving(true);
    try {
      await rideRepo.createVehicle({
        nickname: nick.trim(),
        makeModel: picked.makeModel,
        plateNumber: plate.trim().toUpperCase(),
        seats: seatCount,
        color: color.trim(),
        primary: true,
      });
      invalidate();
      setOpen(false);
      resetForm();
    } catch (e) {
      setError(messageFrom(e));
    } finally {
      setSaving(false);
    }
  };

  const card = (v: Vehicle) => (
    <SoftPanel key={v.id}>
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
        <CarModelIcon makeModel={v.makeModel} size={52} />
        <View style={{ flex: 1 }}>
          <Text style={{ fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi }}>
            {vehicleDisplayName(v)}
            {v.primary ? ' · Primary' : ''}
          </Text>
          <Text style={{ color: colors.inkMuted, fontFamily: fonts.body, fontWeight: weights.body, marginTop: 2 }}>
            {v.makeModel} · {v.plateMasked} · {v.seats} seats{v.color ? ` · ${v.color}` : ''}
          </Text>
        </View>
      </View>
      <View style={{ flexDirection: 'row', gap: 16, marginTop: 10 }}>
        {!v.primary ? (
          <Text
            onPress={async () => {
              await rideRepo.setPrimary(v.id);
              invalidate();
            }}
            style={{ color: colors.brandOrange, fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi }}>
            Make primary
          </Text>
        ) : null}
        <Text
          onPress={() =>
            Alert.alert('Remove vehicle?', `Remove ${vehicleDisplayName(v)}?`, [
              { text: 'Cancel' },
              {
                text: 'Remove',
                style: 'destructive',
                onPress: async () => {
                  await rideRepo.deleteVehicle(v.id);
                  invalidate();
                },
              },
            ])
          }
          style={{ color: colors.danger, fontFamily: fonts.bodySemi, fontWeight: weights.bodySemi }}>
          Remove
        </Text>
      </View>
    </SoftPanel>
  );

  return (
    <SkyScaffold>
      <ScrollView contentContainerStyle={{ padding: 20, gap: 12, paddingBottom: 40 }}>
        {list.length === 0 ? (
          <SoftPanel>
            <EmptyState
              title="No vehicles yet"
              subtitle="Add a car or bike to start offering rides"
              actionLabel="Add vehicle"
              onAction={() => setOpen(true)}
              icon="directions-car"
            />
          </SoftPanel>
        ) : (
          <>
            <Text style={{ color: colors.inkMuted, fontFamily: fonts.body, fontWeight: weights.body }}>
              {list.length} vehicle{list.length === 1 ? '' : 's'} · set a primary
            </Text>
            {list.map(card)}
          </>
        )}
        <PrimaryButton label="Add vehicle" icon="add" onPress={() => setOpen(true)} />
      </ScrollView>
      <Modal visible={open} animationType="slide" onRequestClose={() => setOpen(false)}>
        <SkyScaffold>
          <ScrollView contentContainerStyle={{ padding: 20, gap: 12, paddingBottom: 40 }}>
            <Text style={{ fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi, fontSize: 22, color: colors.ink }}>
              Add vehicle
            </Text>
            <Field label="Nickname (optional)" placeholder="e.g. Office Honda" value={nick} onChangeText={setNick} />
            <CarCatalogFields
              key={formKey}
              color={color}
              onColor={setColor}
              onPicked={(selection) => {
                setPicked(selection);
                if (selection?.seats) setSeats(String(selection.seats));
              }}
            />
            <Field
              label="Plate number"
              placeholder="e.g. TS09AB1234"
              autoCapitalize="characters"
              value={plate}
              onChangeText={(text) => setPlate(text.toUpperCase())}
            />
            <Field label="Seats" keyboardType="number-pad" value={seats} onChangeText={setSeats} />
            {error ? <ErrorBanner message={error} /> : null}
            <PrimaryButton label="Save vehicle" loading={saving} onPress={save} />
            <OutlineButton
              label="Close"
              onPress={() => {
                setOpen(false);
                resetForm();
              }}
            />
          </ScrollView>
        </SkyScaffold>
      </Modal>
    </SkyScaffold>
  );
}
