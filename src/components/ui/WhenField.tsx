import DateTimePicker from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { useState } from 'react';
import { Platform, Pressable, Text, View } from 'react-native';

import { colors, fonts, weights } from '@/src/theme/colors';

type Props = {
  value: Date;
  onChange: (next: Date) => void;
  label?: string;
  minimumDate?: Date;
};

function pad(n: number) {
  return String(n).padStart(2, '0');
}

function toLocalInput(d: Date) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export function WhenField({ value, onChange, label = 'Date and time', minimumDate }: Props) {
  const [phase, setPhase] = useState<'closed' | 'date' | 'time'>('closed');

  if (Platform.OS === 'web') {
    return (
      <View style={box}>
        <Text style={meta}>{label}</Text>
        <input
          type="datetime-local"
          value={toLocalInput(value)}
          min={minimumDate ? toLocalInput(minimumDate) : undefined}
          onChange={(event) => {
            if (!event.target.value) return;
            onChange(new Date(event.target.value));
          }}
          style={{
            marginTop: 6,
            width: '100%',
            border: 'none',
            outline: 'none',
            background: 'transparent',
            fontFamily: fonts.displaySemi,
            fontWeight: weights.displaySemi,
            fontSize: 16,
            color: colors.ink,
          }}
        />
      </View>
    );
  }

  return (
    <View>
      <Pressable onPress={() => setPhase('date')} style={box}>
        <Text style={meta}>{label}</Text>
        <Text style={valueText}>{format(value, 'EEEE, d MMM · h:mm a')}</Text>
      </Pressable>
      {phase !== 'closed' ? (
        <DateTimePicker
          value={value}
          mode={Platform.OS === 'ios' ? 'datetime' : phase}
          minimumDate={minimumDate}
          onChange={(_, next) => {
            if (Platform.OS === 'ios') {
              if (next) onChange(next);
              return;
            }
            if (!next) {
              setPhase('closed');
              return;
            }
            if (phase === 'date') {
              const merged = new Date(value);
              merged.setFullYear(next.getFullYear(), next.getMonth(), next.getDate());
              onChange(merged);
              setPhase('time');
              return;
            }
            const merged = new Date(value);
            merged.setHours(next.getHours(), next.getMinutes(), 0, 0);
            onChange(merged);
            setPhase('closed');
          }}
        />
      ) : null}
    </View>
  );
}

const box = {
  backgroundColor: colors.surfaceElevated,
  borderRadius: 16,
  borderWidth: 1,
  borderColor: colors.line,
  padding: 14,
};
const meta = { fontFamily: fonts.body, fontWeight: weights.body, fontSize: 13, color: colors.inkMuted } as const;
const valueText = { fontFamily: fonts.displaySemi, fontWeight: weights.displaySemi, fontSize: 16, color: colors.ink, marginTop: 4 } as const;
