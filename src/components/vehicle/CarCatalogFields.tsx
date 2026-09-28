import { useMemo, useState, type ReactNode } from 'react';
import { Pressable, ScrollView, Text, TextInput, View } from 'react-native';

import {
  CAR_COLORS,
  CarModel,
  CarVariant,
  carBrands,
  findBrand,
  findModel,
  formatMakeModel,
  searchCatalog,
  variantYears,
} from '@/src/data/carCatalog';
import { colors, fonts, weights } from '@/src/theme/colors';

export type CarSelection = {
  brand: string;
  model: string;
  variant: string;
  year: number;
  seats: number;
  fuel: string;
  makeModel: string;
};

type Step = 'brand' | 'model' | 'variant' | 'year';

type Props = {
  color: string;
  onColor: (value: string) => void;
  onPicked: (selection: CarSelection | null) => void;
};

export function CarCatalogFields({ color, onColor, onPicked }: Props) {
  const [query, setQuery] = useState('');
  const [brandName, setBrandName] = useState('');
  const [modelName, setModelName] = useState('');
  const [variantName, setVariantName] = useState('');
  const [year, setYear] = useState<number | null>(null);
  const [other, setOther] = useState(false);
  const [otherText, setOtherText] = useState('');
  const [open, setOpen] = useState<Step | null>('brand');

  const brand = findBrand(brandName);
  const model = findModel(brand, modelName);
  const variant = model?.variants.find((item) => item.name === variantName);
  const years = variant ? variantYears(variant) : [];
  const searchHits = useMemo(() => searchCatalog(query), [query]);
  const searching = query.trim().length >= 2;

  const commit = (nextBrand: string, nextModel: string, nextVariant: CarVariant, nextYear: number) => {
    onPicked({
      brand: nextBrand,
      model: nextModel,
      variant: nextVariant.name,
      year: nextYear,
      seats: nextVariant.seats,
      fuel: nextVariant.fuel,
      makeModel: formatMakeModel(nextBrand, nextModel, nextVariant.name, nextYear),
    });
  };

  const pickBrand = (name: string) => {
    setOther(false);
    setBrandName(name);
    setModelName('');
    setVariantName('');
    setYear(null);
    setQuery('');
    setOpen('model');
    onPicked(null);
  };

  const pickModel = (next: CarModel) => {
    setModelName(next.name);
    setVariantName('');
    setYear(null);
    setQuery('');
    setOpen('variant');
    onPicked(null);
  };

  const pickVariant = (next: CarVariant) => {
    const latest = variantYears(next)[0];
    setVariantName(next.name);
    setYear(latest);
    setOpen(null);
    if (brand && modelName && latest) commit(brand.name, modelName, next, latest);
  };

  const pickYear = (nextYear: number) => {
    if (!brand || !model || !variant) return;
    setYear(nextYear);
    setOpen(null);
    commit(brand.name, model.name, variant, nextYear);
  };

  const reopen = (step: Step) => {
    if (step === 'brand') {
      setModelName('');
      setVariantName('');
      setYear(null);
      onPicked(null);
    } else if (step === 'model') {
      setVariantName('');
      setYear(null);
      onPicked(null);
    } else if (step === 'variant') {
      setYear(null);
      onPicked(null);
    }
    setOpen(step);
  };

  const done = Boolean(year && brandName && modelName && variantName && !other);

  return (
    <View style={{ gap: 14 }}>
      <TextInput
        value={query}
        onChangeText={(text) => {
          setQuery(text);
          if (text.trim().length >= 2) setOpen('brand');
        }}
        placeholder="Search brand or model"
        placeholderTextColor={colors.inkMuted}
        style={field}
      />

      {searching ? (
        <List>
          {searchHits.length === 0 ? (
            <Text style={hint}>No match. Type another name, or pick a brand below.</Text>
          ) : (
            searchHits.map((hit) => (
              <Choice
                key={`${hit.brand}-${hit.model}`}
                title={`${hit.brand} ${hit.model}`}
                onPress={() => {
                  const found = findBrand(hit.brand);
                  const foundModel = findModel(found, hit.model);
                  pickBrand(hit.brand);
                  if (foundModel) pickModel(foundModel);
                }}
              />
            ))
          )}
        </List>
      ) : null}

      {done ? (
        <View style={{ padding: 12, borderRadius: 16, backgroundColor: `${colors.brandBlue}0D` }}>
          <Text style={titleStyle}>{formatMakeModel(brandName, modelName, variantName, year!)}</Text>
        </View>
      ) : null}

      {!searching ? (
        <>
          <Picked label="Brand" value={other ? 'Other' : brandName} onPress={() => reopen('brand')} />
          {open === 'brand' || !brandName ? (
            <List>
              {carBrands.map((item) => (
                <Choice
                  key={item.name}
                  title={item.name}
                  active={brandName === item.name && !other}
                  onPress={() => pickBrand(item.name)}
                />
              ))}
              <Choice
                title="Other"
                active={other}
                onPress={() => {
                  setOther(true);
                  setBrandName('');
                  setModelName('');
                  setVariantName('');
                  setYear(null);
                  setOpen(null);
                  onPicked(null);
                }}
              />
            </List>
          ) : null}
        </>
      ) : null}

      {other ? (
        <TextInput
          value={otherText}
          onChangeText={(text) => {
            setOtherText(text);
            const trimmed = text.trim();
            onPicked(
              trimmed
                ? {
                    brand: 'Other',
                    model: trimmed,
                    variant: '',
                    year: 0,
                    seats: 5,
                    fuel: '',
                    makeModel: trimmed,
                  }
                : null,
            );
          }}
          placeholder="Type make, model, variant and year"
          placeholderTextColor={colors.inkMuted}
          style={field}
        />
      ) : null}

      {brand && !other ? (
        <>
          <Picked label="Model" value={modelName} onPress={() => reopen('model')} />
          {open === 'model' || !modelName ? (
            <List>
              {brand.models.map((item) => (
                <Choice
                  key={item.name}
                  title={item.name}
                  active={modelName === item.name}
                  onPress={() => pickModel(item)}
                />
              ))}
            </List>
          ) : null}
        </>
      ) : null}

      {model && !other ? (
        <>
          <Picked label="Variant" value={variantName} onPress={() => reopen('variant')} />
          {open === 'variant' || !variantName ? (
            <List>
              {model.variants.map((item) => (
                <Choice
                  key={item.name}
                  title={item.name}
                  subtitle={`${item.seats} seats · ${item.fuel}`}
                  active={variantName === item.name}
                  onPress={() => pickVariant(item)}
                />
              ))}
            </List>
          ) : null}
        </>
      ) : null}

      {variant && !other ? (
        <>
          <Picked label="Year" value={year ? String(year) : ''} onPress={() => reopen('year')} />
          {open === 'year' || !year ? (
            <List>
              {years.map((item) => (
                <Choice key={item} title={String(item)} active={year === item} onPress={() => pickYear(item)} />
              ))}
            </List>
          ) : null}
        </>
      ) : null}

      <Label>Color</Label>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {CAR_COLORS.map((item) => (
          <Pressable
            key={item}
            onPress={() => onColor(item)}
            style={{
              paddingHorizontal: 12,
              paddingVertical: 8,
              borderRadius: 999,
              backgroundColor: color === item ? `${colors.brandBlue}1A` : colors.skyMid,
              borderWidth: 1,
              borderColor: color === item ? colors.brandBlue : colors.line,
            }}>
            <Text style={[choiceTitle, color === item && { color: colors.brandBlue }]}>{item}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

function Label({ children }: { children: string }) {
  return <Text style={labelStyle}>{children}</Text>;
}

function Picked({ label: caption, value, onPress }: { label: string; value: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={pickedRow}>
      <Text style={labelStyle}>{caption}</Text>
      <Text style={value ? titleStyle : hint}>{value || 'Choose'}</Text>
    </Pressable>
  );
}

function List({ children }: { children: ReactNode }) {
  return (
    <ScrollView
      style={{ maxHeight: 220, borderWidth: 1, borderColor: colors.line, borderRadius: 16, backgroundColor: colors.surfaceElevated }}
      nestedScrollEnabled
      keyboardShouldPersistTaps="handled">
      {children}
    </ScrollView>
  );
}

function Choice({
  title,
  subtitle,
  active,
  onPress,
}: {
  title: string;
  subtitle?: string;
  active?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        paddingHorizontal: 14,
        paddingVertical: 12,
        backgroundColor: active ? `${colors.brandBlue}0F` : 'transparent',
        borderBottomWidth: 1,
        borderBottomColor: colors.line,
      }}>
      <Text style={[choiceTitle, active && { color: colors.brandBlue }]}>{title}</Text>
      {subtitle ? <Text style={hint}>{subtitle}</Text> : null}
    </Pressable>
  );
}

const field = {
  backgroundColor: colors.surfaceElevated,
  borderWidth: 1,
  borderColor: colors.line,
  borderRadius: 14,
  paddingHorizontal: 14,
  paddingVertical: 12,
  fontFamily: fonts.body,
  fontWeight: weights.body,
  fontSize: 16,
  color: colors.ink,
};
const labelStyle = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 13,
  color: colors.inkMuted,
} as const;
const titleStyle = {
  fontFamily: fonts.displaySemi,
  fontWeight: weights.displaySemi,
  fontSize: 16,
  color: colors.ink,
} as const;
const choiceTitle = {
  fontFamily: fonts.bodySemi,
  fontWeight: weights.bodySemi,
  fontSize: 15,
  color: colors.ink,
} as const;
const hint = { fontFamily: fonts.body, fontWeight: weights.body, fontSize: 13, color: colors.inkMuted, marginTop: 2 } as const;
const pickedRow = {
  gap: 4,
} as const;
