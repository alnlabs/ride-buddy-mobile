export const CATALOG_YEAR_NOW = 2026;

export type CarFuel = 'Petrol' | 'Diesel' | 'CNG' | 'Hybrid' | 'Electric' | 'Petrol/CNG' | 'Petrol/Diesel';

export type CarVariant = {
  name: string;
  yearFrom: number;
  yearTo: number;
  seats: number;
  fuel: CarFuel;
};

export type CarModel = {
  name: string;
  variants: CarVariant[];
};

export type CarBrand = {
  name: string;
  models: CarModel[];
};

function v(name: string, yearFrom: number, yearTo: number, seats = 5, fuel: CarFuel = 'Petrol'): CarVariant {
  return { name, yearFrom, yearTo, seats, fuel };
}

function pack(
  names: string[],
  yearFrom: number,
  yearTo: number,
  seats = 5,
  fuel: CarFuel = 'Petrol',
): CarVariant[] {
  return names.map((name) => v(name, yearFrom, yearTo, seats, fuel));
}

function yearsOf(variant: CarVariant): number[] {
  const out: number[] = [];
  for (let y = variant.yearTo; y >= variant.yearFrom; y -= 1) out.push(y);
  return out;
}

export function variantYears(variant: CarVariant): number[] {
  return yearsOf(variant);
}

export function formatMakeModel(brand: string, model: string, variant: string, year: number): string {
  return `${brand} ${model} ${variant} ${year}`;
}

export const CAR_COLORS = [
  'White',
  'Silver',
  'Grey',
  'Black',
  'Red',
  'Blue',
  'Brown',
  'Beige',
  'Orange',
  'Green',
  'Maroon',
  'Gold',
];

export const carBrands: CarBrand[] = [
  {
    name: 'Maruti Suzuki',
    models: [
      { name: 'Alto', variants: pack(['Std', 'LXi', 'VXi', 'VXi+'], 2010, 2019, 5, 'Petrol/CNG') },
      { name: 'Alto 800', variants: pack(['Std', 'LXi', 'VXi', 'VXi+ (O)'], 2012, 2023, 5, 'Petrol/CNG') },
      { name: 'Alto K10', variants: pack(['Std', 'LXi', 'VXi', 'VXi+', 'ZXi', 'ZXi+'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'S-Presso', variants: pack(['Std', 'LXi', 'VXi', 'VXi+', 'ZXi', 'ZXi+'], 2019, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Celerio', variants: pack(['LXi', 'VXi', 'ZXi', 'ZXi+', 'VXi AMT', 'ZXi AMT'], 2014, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Wagon R', variants: pack(['LXi', 'VXi', 'ZXi', 'ZXi+', 'VXi CNG', 'ZXi CNG'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Ignis', variants: pack(['Sigma', 'Delta', 'Zeta', 'Alpha'], 2017, CATALOG_YEAR_NOW) },
      { name: 'Swift', variants: pack(['LXi', 'VXi', 'ZXi', 'ZXi+', 'VXi AMT', 'ZXi AMT'], 2011, CATALOG_YEAR_NOW) },
      { name: 'Dzire', variants: pack(['LXi', 'VXi', 'ZXi', 'ZXi+', 'VXi CNG', 'ZXi CNG'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Baleno', variants: pack(['Sigma', 'Delta', 'Zeta', 'Alpha', 'Alpha Dualjet'], 2015, CATALOG_YEAR_NOW) },
      { name: 'Fronx', variants: pack(['Sigma', 'Delta', 'Delta+', 'Zeta', 'Alpha', 'Alpha Dualjet'], 2023, CATALOG_YEAR_NOW) },
      { name: 'Brezza', variants: pack(['LXi', 'VXi', 'ZXi', 'ZXi+', 'ZXi+ AT'], 2016, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Grand Vitara', variants: pack(['Sigma', 'Delta', 'Zeta', 'Alpha', 'Alpha+', 'Zeta Hybrid', 'Alpha Hybrid'], 2022, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'Jimny', variants: pack(['Zeta', 'Alpha', 'Alpha AT'], 2023, CATALOG_YEAR_NOW, 4) },
      { name: 'Ertiga', variants: pack(['LXi', 'VXi', 'ZXi', 'ZXi+', 'VXi CNG', 'ZXi CNG'], 2012, CATALOG_YEAR_NOW, 7, 'Petrol/CNG') },
      { name: 'XL6', variants: pack(['Zeta', 'Alpha', 'Alpha+'], 2019, CATALOG_YEAR_NOW, 6, 'Petrol/CNG') },
      { name: 'Invicto', variants: pack(['Zeta+', 'Alpha+', 'Alpha+ 7STR'], 2023, CATALOG_YEAR_NOW, 7, 'Hybrid') },
      { name: 'Ciaz', variants: pack(['Sigma', 'Delta', 'Zeta', 'Alpha'], 2014, 2024) },
      { name: 'S-Cross', variants: pack(['Sigma', 'Delta', 'Zeta', 'Alpha'], 2015, 2022, 5, 'Petrol/Diesel') },
      { name: 'Eeco', variants: pack(['5 STR', '7 STR', 'AC 5 STR', 'CNG 5 STR'], 2010, CATALOG_YEAR_NOW, 7, 'Petrol/CNG') },
      { name: 'Ritz', variants: pack(['LXi', 'VXi', 'ZXi', 'VDi', 'ZDi'], 2009, 2017, 5, 'Petrol/Diesel') },
      { name: 'Gypsy', variants: pack(['King Soft Top', 'King Hard Top'], 1996, 2018, 7, 'Petrol') },
    ],
  },
  {
    name: 'Hyundai',
    models: [
      { name: 'Santro', variants: pack(['Era', 'Magna', 'Sportz', 'Asta', 'Magna CNG'], 2018, 2022, 5, 'Petrol/CNG') },
      { name: 'Grand i10', variants: pack(['Era', 'Magna', 'Sportz', 'Asta', 'Asta (O)'], 2013, 2019, 5, 'Petrol/Diesel') },
      { name: 'Grand i10 Nios', variants: pack(['Era', 'Magna', 'Sportz', 'Asta', 'Asta (O)', 'Sportz CNG'], 2019, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'i10', variants: pack(['Era', 'Magna', 'Sportz', 'Asta'], 2007, 2014) },
      { name: 'i20', variants: pack(['Magna', 'Sportz', 'Asta', 'Asta (O)', 'N Line N8', 'N Line N8 DCT'], 2010, CATALOG_YEAR_NOW) },
      { name: 'Aura', variants: pack(['E', 'S', 'SX', 'SX+', 'SX (O)', 'S CNG'], 2020, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Xcent', variants: pack(['E', 'S', 'SX', 'SX (O)'], 2014, 2020, 5, 'Petrol/Diesel') },
      { name: 'Verna', variants: pack(['EX', 'S', 'SX', 'SX (O)', 'SX (O) DCT'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Elantra', variants: pack(['S', 'SX', 'SX (O)'], 2012, 2020, 5, 'Petrol/Diesel') },
      { name: 'Exter', variants: pack(['EX', 'S', 'SX', 'SX (O)', 'SX (O) Connect'], 2023, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Venue', variants: pack(['E', 'S', 'SX', 'SX (O)', 'SX (O) DCT', 'N Line N8'], 2019, CATALOG_YEAR_NOW) },
      { name: 'Creta', variants: pack(['E', 'EX', 'S', 'SX', 'SX (O)', 'SX (O) Knight', 'SX (O) DCT'], 2015, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Alcazar', variants: pack(['Prestige', 'Platinum', 'Signature', 'Signature (O)'], 2021, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Tucson', variants: pack(['Platinum', 'Signature', 'Signature 4WD'], 2016, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Kona Electric', variants: pack(['Premium', 'Premium Dual Tone'], 2019, 2023, 5, 'Electric') },
      { name: 'Ioniq 5', variants: pack(['RWD', 'AWD Long Range'], 2023, CATALOG_YEAR_NOW, 5, 'Electric') },
    ],
  },
  {
    name: 'Tata',
    models: [
      { name: 'Nano', variants: pack(['Std', 'CX', 'LX', 'Twist'], 2009, 2018, 4) },
      { name: 'Tiago', variants: pack(['XE', 'XM', 'XT', 'XZ', 'XZ+', 'XT CNG'], 2016, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Tigor', variants: pack(['XE', 'XM', 'XZ', 'XZ+', 'XZ+ CNG'], 2017, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Altroz', variants: pack(['XE', 'XM', 'XT', 'XZ', 'XZ+', 'XZ+ Dark'], 2020, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Punch', variants: pack(['Pure', 'Adventure', 'Accomplished', 'Creative', 'Creative AMT'], 2021, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Nexon', variants: pack(['Creative', 'Fearless', 'Fearless+', 'Fearless+ S', 'Creative Dark'], 2017, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Harrier', variants: pack(['Smart', 'Pure', 'Adventure', 'Fearless', 'Fearless+', 'Fearless+ Dark'], 2019, CATALOG_YEAR_NOW, 5, 'Diesel') },
      { name: 'Safari', variants: pack(['Smart', 'Pure', 'Adventure', 'Accomplished', 'Fearless+', 'Fearless+ Dark'], 2021, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'Curvv', variants: pack(['Smart', 'Creative', 'Accomplished', 'Accomplished+', 'Fearless+'], 2024, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Tiago EV', variants: pack(['XE MR', 'XT MR', 'XT LR', 'XZ+ LR'], 2022, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Tigor EV', variants: pack(['XE', 'XM', 'XZ+', 'XZ+ Lux'], 2021, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Punch EV', variants: pack(['Smart', 'Adventure', 'Empowered', 'Empowered+', 'Empowered+ S'], 2024, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Nexon EV', variants: pack(['Creative', 'Fearless', 'Fearless+', 'Empowered+', 'Empowered+ Dark'], 2020, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Curvv EV', variants: pack(['Creative 45', 'Accomplished 55', 'Empowered+ 55'], 2024, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Bolt', variants: pack(['XE', 'XM', 'XT', 'XMS'], 2015, 2019) },
      { name: 'Zest', variants: pack(['XE', 'XM', 'XT', 'XTA'], 2014, 2019, 5, 'Petrol/Diesel') },
      { name: 'Hexa', variants: pack(['XE', 'XM', 'XT', 'XTA', 'XT 4x4'], 2017, 2020, 7, 'Diesel') },
    ],
  },
  {
    name: 'Honda',
    models: [
      { name: 'Brio', variants: pack(['E', 'S', 'VX', 'VX (O)'], 2011, 2019) },
      { name: 'Jazz', variants: pack(['V', 'VX', 'ZX'], 2009, 2023) },
      { name: 'Amaze', variants: pack(['E', 'S', 'VX', 'VX CVT', 'ZX'], 2013, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'City', variants: pack(['V', 'VX', 'ZX', 'ZX CVT', 'ZX e:HEV'], 2010, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'Civic', variants: pack(['V', 'VX', 'ZX'], 2006, 2022) },
      { name: 'WR-V', variants: pack(['S', 'VX', 'VX CVT'], 2017, 2023) },
      { name: 'BR-V', variants: pack(['E', 'S', 'V', 'VX'], 2016, 2020, 7) },
      { name: 'Elevate', variants: pack(['SV', 'V', 'VX', 'ZX', 'ZX CVT'], 2023, CATALOG_YEAR_NOW) },
      { name: 'CR-V', variants: pack(['2WD', 'AWD', 'Diesel AWD'], 2013, 2026, 5, 'Petrol/Diesel') },
      { name: 'Accord', variants: pack(['Elegance', 'Hybrid'], 2008, 2020, 5, 'Hybrid') },
    ],
  },
  {
    name: 'Toyota',
    models: [
      { name: 'Etios', variants: pack(['J', 'G', 'V', 'VX', 'VD'], 2010, 2020, 5, 'Petrol/Diesel') },
      { name: 'Etios Liva', variants: pack(['J', 'G', 'V', 'VX'], 2011, 2020, 5, 'Petrol/Diesel') },
      { name: 'Yaris', variants: pack(['J', 'G', 'V', 'VX'], 2018, 2021) },
      { name: 'Glanza', variants: pack(['E', 'S', 'G', 'V', 'V AMT', 'S CNG'], 2019, CATALOG_YEAR_NOW, 5, 'Petrol/CNG') },
      { name: 'Urban Cruiser', variants: pack(['Mid', 'High', 'Premium'], 2020, 2022) },
      { name: 'Urban Cruiser Hyryder', variants: pack(['E', 'S', 'G', 'V', 'S Hybrid', 'V Hybrid'], 2022, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'Urban Cruiser Taisor', variants: pack(['E', 'S', 'S+', 'V'], 2024, CATALOG_YEAR_NOW) },
      { name: 'Rumion', variants: pack(['S', 'G', 'V', 'S CNG'], 2023, CATALOG_YEAR_NOW, 7, 'Petrol/CNG') },
      { name: 'Innova', variants: pack(['G', 'GX', 'VX', 'ZX'], 2005, 2016, 8, 'Petrol/Diesel') },
      { name: 'Innova Crysta', variants: pack(['GX', 'VX', 'ZX', 'Touring Sport'], 2016, CATALOG_YEAR_NOW, 8, 'Diesel') },
      { name: 'Innova Hycross', variants: pack(['GX', 'VX', 'ZX', 'ZX (O) Hybrid'], 2023, CATALOG_YEAR_NOW, 8, 'Hybrid') },
      { name: 'Fortuner', variants: pack(['4x2 MT', '4x2 AT', '4x4 MT', '4x4 AT', 'Legender'], 2009, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'Hilux', variants: pack(['STD', 'High', 'High 4x4'], 2022, CATALOG_YEAR_NOW, 5, 'Diesel') },
      { name: 'Camry', variants: pack(['Hybrid'], 2012, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'Land Cruiser Prado', variants: pack(['VX', 'VX-L'], 2010, 2020, 7, 'Diesel') },
      { name: 'Vellfire', variants: pack(['Executive Lounge', 'VIP'], 2020, CATALOG_YEAR_NOW, 7, 'Hybrid') },
    ],
  },
  {
    name: 'Mahindra',
    models: [
      { name: 'KUV100', variants: pack(['K2', 'K4', 'K6', 'K8'], 2016, 2023, 6) },
      { name: 'XUV300', variants: pack(['W4', 'W6', 'W8', 'W8 (O)', 'W8 (O) AMT'], 2019, 2024, 5, 'Petrol/Diesel') },
      { name: 'XUV 3XO', variants: pack(['MX1', 'MX2', 'MX3', 'AX5', 'AX7', 'AX7 L'], 2024, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'XUV400', variants: pack(['EC', 'EL', 'EL Pro'], 2023, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'XUV500', variants: pack(['W5', 'W7', 'W9', 'W11', 'W11 (O)'], 2011, 2021, 7, 'Diesel') },
      { name: 'XUV700', variants: pack(['MX', 'AX3', 'AX5', 'AX7', 'AX7 L'], 2021, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Scorpio', variants: pack(['S3', 'S5', 'S7', 'S9', 'S11'], 2002, 2022, 7, 'Diesel') },
      { name: 'Scorpio-N', variants: pack(['Z2', 'Z4', 'Z6', 'Z8', 'Z8 L'], 2022, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Scorpio Classic', variants: pack(['S', 'S11'], 2022, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'Bolero', variants: pack(['B4', 'B6', 'B6 (O)', 'B8'], 2011, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'Bolero Neo', variants: pack(['N4', 'N8', 'N10', 'N10 (O)'], 2021, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'Thar', variants: pack(['AX (O) RWD', 'LX RWD', 'LX 4WD', 'LX 4WD AT'], 2010, CATALOG_YEAR_NOW, 4, 'Petrol/Diesel') },
      { name: 'Thar Roxx', variants: pack(['MX1', 'MX3', 'AX5', 'AX7', 'AX7 L'], 2024, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Marazzo', variants: pack(['M2', 'M4', 'M6', 'M8'], 2018, 2023, 8, 'Diesel') },
      { name: 'BE 6', variants: pack(['Pack One', 'Pack Two', 'Pack Three'], 2025, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'XEV 9e', variants: pack(['Pack One', 'Pack Two', 'Pack Three'], 2025, CATALOG_YEAR_NOW, 5, 'Electric') },
    ],
  },
  {
    name: 'Kia',
    models: [
      { name: 'Sonet', variants: pack(['HTE', 'HTK', 'HTK+', 'HTX', 'HTX+', 'GTX+', 'X-Line'], 2020, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Seltos', variants: pack(['HTE', 'HTK', 'HTK+', 'HTX', 'HTX+', 'GTX+', 'X-Line'], 2019, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Syros', variants: pack(['HTE', 'HTK', 'HTK+', 'HTX', 'HTX+'], 2025, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Carens', variants: pack(['Premium', 'Prestige', 'Prestige+', 'Luxury', 'Luxury+', 'X-Line'], 2022, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Carnival', variants: pack(['Premium', 'Prestige', 'Limousine', 'Limousine+'], 2020, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'EV6', variants: pack(['GT-Line RWD', 'GT-Line AWD'], 2022, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'EV9', variants: pack(['GT-Line AWD'], 2024, CATALOG_YEAR_NOW, 6, 'Electric') },
    ],
  },
  {
    name: 'MG',
    models: [
      { name: 'Hector', variants: pack(['Style', 'Super', 'Smart', 'Sharp', 'Sharp Pro', 'Savvy Pro'], 2019, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Hector Plus', variants: pack(['Style', 'Super', 'Smart', 'Sharp', 'Savvy Pro'], 2020, CATALOG_YEAR_NOW, 6, 'Petrol/Diesel') },
      { name: 'Astor', variants: pack(['Style', 'Super', 'Smart', 'Sharp', 'Savvy'], 2021, CATALOG_YEAR_NOW) },
      { name: 'ZS EV', variants: pack(['Executive', 'Excite', 'Exclusive'], 2020, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Comet EV', variants: pack(['Executive', 'Excite', 'Exclusive', 'Play'], 2023, CATALOG_YEAR_NOW, 4, 'Electric') },
      { name: 'Windsor', variants: pack(['Excite', 'Exclusive', 'Essence'], 2024, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Gloster', variants: pack(['Super', 'Sharp', 'Savvy 6 STR', 'Savvy 7 STR'], 2020, CATALOG_YEAR_NOW, 7, 'Diesel') },
    ],
  },
  {
    name: 'Volkswagen',
    models: [
      { name: 'Polo', variants: pack(['Trendline', 'Comfortline', 'Highline', 'Highline Plus', 'GT TSI'], 2010, 2022) },
      { name: 'Vento', variants: pack(['Trendline', 'Comfortline', 'Highline', 'Highline Plus'], 2010, 2022, 5, 'Petrol/Diesel') },
      { name: 'Ameo', variants: pack(['Trendline', 'Comfortline', 'Highline', 'Highline Plus'], 2016, 2020, 5, 'Petrol/Diesel') },
      { name: 'Virtus', variants: pack(['Comfortline', 'Highline', 'Topline', 'GT', 'GT Plus'], 2022, CATALOG_YEAR_NOW) },
      { name: 'Taigun', variants: pack(['Comfortline', 'Highline', 'Topline', 'GT', 'GT Plus'], 2021, CATALOG_YEAR_NOW) },
      { name: 'Tiguan', variants: pack(['Elegance', 'R-Line'], 2017, CATALOG_YEAR_NOW, 5, 'Petrol') },
    ],
  },
  {
    name: 'Skoda',
    models: [
      { name: 'Fabia', variants: pack(['Active', 'Ambition', 'Elegance'], 2008, 2014) },
      { name: 'Rapid', variants: pack(['Active', 'Ambition', 'Style', 'Monte Carlo'], 2011, 2021, 5, 'Petrol/Diesel') },
      { name: 'Octavia', variants: pack(['Ambition', 'Style', 'L&K', 'RS'], 2010, 2023, 5, 'Petrol/Diesel') },
      { name: 'Superb', variants: pack(['Corporate', 'Style', 'L&K', 'Sportline'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Slavia', variants: pack(['Classic', 'Ambition', 'Style', 'Prestige', 'Monte Carlo'], 2022, CATALOG_YEAR_NOW) },
      { name: 'Kushaq', variants: pack(['Active', 'Ambition', 'Style', 'Prestige', 'Monte Carlo'], 2021, CATALOG_YEAR_NOW) },
      { name: 'Kodiaq', variants: pack(['Style', 'L&K', 'Sportline'], 2017, CATALOG_YEAR_NOW, 7, 'Petrol') },
      { name: 'Yeti', variants: pack(['Active', 'Ambition', 'Elegance'], 2010, 2017, 5, 'Diesel') },
    ],
  },
  {
    name: 'Renault',
    models: [
      { name: 'Kwid', variants: pack(['RXE', 'RXL', 'RXT', 'Climber', 'Climber AMT'], 2015, CATALOG_YEAR_NOW) },
      { name: 'Triber', variants: pack(['RXE', 'RXL', 'RXT', 'RXZ'], 2019, CATALOG_YEAR_NOW, 7) },
      { name: 'Kiger', variants: pack(['RXE', 'RXL', 'RXT', 'RXZ', 'RXZ AMT'], 2021, CATALOG_YEAR_NOW) },
      { name: 'Duster', variants: pack(['RxE', 'RxL', 'RxZ', 'RxZ AWD'], 2012, 2022, 5, 'Petrol/Diesel') },
      { name: 'Captur', variants: pack(['RXE', 'RXL', 'RXT', 'Platine'], 2017, 2020, 5, 'Petrol/Diesel') },
      { name: 'Lodgy', variants: pack(['RxE', 'RxL', 'RxZ', 'Stepway'], 2015, 2020, 8, 'Diesel') },
    ],
  },
  {
    name: 'Nissan',
    models: [
      { name: 'Micra', variants: pack(['XE', 'XL', 'XV', 'XV Premium'], 2010, 2019) },
      { name: 'Sunny', variants: pack(['XE', 'XL', 'XV', 'XV Premium'], 2011, 2020, 5, 'Petrol/Diesel') },
      { name: 'Terrano', variants: pack(['XE', 'XL', 'XV', 'XV Premium'], 2013, 2019, 5, 'Diesel') },
      { name: 'Kicks', variants: pack(['XL', 'XV', 'XV Premium'], 2019, 2023) },
      { name: 'Magnite', variants: pack(['XE', 'XL', 'XV', 'XV Premium', 'Geza'], 2020, CATALOG_YEAR_NOW) },
    ],
  },
  {
    name: 'Ford',
    models: [
      { name: 'Figo', variants: pack(['Ambiente', 'Trend', 'Titanium', 'Titanium+', 'Sports'], 2010, 2021, 5, 'Petrol/Diesel') },
      { name: 'Aspire', variants: pack(['Ambiente', 'Trend', 'Titanium', 'Titanium+'], 2015, 2021, 5, 'Petrol/Diesel') },
      { name: 'Freestyle', variants: pack(['Ambiente', 'Trend', 'Titanium', 'Titanium+'], 2018, 2021) },
      { name: 'EcoSport', variants: pack(['Ambiente', 'Trend', 'Titanium', 'Titanium+', 'Sports'], 2013, 2021, 5, 'Petrol/Diesel') },
      { name: 'Fiesta', variants: pack(['Style', 'Trend', 'Titanium'], 2005, 2016, 5, 'Petrol/Diesel') },
      { name: 'Endeavour', variants: pack(['Trend', 'Titanium', 'Titanium+', 'Sport'], 2003, 2021, 7, 'Diesel') },
    ],
  },
  {
    name: 'Chevrolet',
    models: [
      { name: 'Beat', variants: pack(['PS', 'LS', 'LT', 'LTZ'], 2010, 2017, 5, 'Petrol/Diesel') },
      { name: 'Spark', variants: pack(['PS', 'LS', 'LT'], 2007, 2017) },
      { name: 'Sail', variants: pack(['LS', 'LT', 'LTZ'], 2012, 2017, 5, 'Petrol/Diesel') },
      { name: 'Cruze', variants: pack(['LT', 'LTZ'], 2009, 2017, 5, 'Diesel') },
      { name: 'Enjoy', variants: pack(['LS', 'LT', 'LTZ'], 2013, 2017, 8, 'Petrol/Diesel') },
    ],
  },
  {
    name: 'Citroen',
    models: [
      { name: 'C3', variants: pack(['Live', 'Feel', 'Feel Sport'], 2022, CATALOG_YEAR_NOW) },
      { name: 'eC3', variants: pack(['Live', 'Feel'], 2023, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'C3 Aircross', variants: pack(['Live', 'Feel', 'Max 5 STR', 'Max 7 STR'], 2023, CATALOG_YEAR_NOW, 7) },
      { name: 'Basalt', variants: pack(['You', 'Plus', 'Max'], 2024, CATALOG_YEAR_NOW) },
    ],
  },
  {
    name: 'Jeep',
    models: [
      { name: 'Compass', variants: pack(['Sport', 'Longitude', 'Limited', 'Model S', 'Trailhawk'], 2017, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Meridian', variants: pack(['Limited', 'Limited (O)', 'Overland'], 2022, CATALOG_YEAR_NOW, 7, 'Diesel') },
      { name: 'Wrangler', variants: pack(['Unlimited Sport', 'Unlimited Rubicon'], 2019, CATALOG_YEAR_NOW, 5, 'Petrol') },
      { name: 'Grand Cherokee', variants: pack(['Limited', 'Summit Reserve'], 2022, CATALOG_YEAR_NOW, 5, 'Petrol') },
    ],
  },
  {
    name: 'BMW',
    models: [
      { name: '1 Series', variants: pack(['118d', '118i'], 2012, 2019, 5, 'Petrol/Diesel') },
      { name: '2 Series Gran Coupe', variants: pack(['218i Sport', '220i M Sport', '220d M Sport'], 2020, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: '3 Series', variants: pack(['320i', '330i', '320d', 'M340i'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: '5 Series', variants: pack(['520d', '530i', '530d', 'M5'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: '7 Series', variants: pack(['730Ld', '740i', '760Li'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'X1', variants: pack(['sDrive18i', 'sDrive20i', 'xDrive20d'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'X3', variants: pack(['xDrive20d', 'xDrive30i', 'M40i'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'X5', variants: pack(['xDrive30d', 'xDrive40i', 'M Competition'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'X7', variants: pack(['xDrive40i', 'xDrive40d', 'M60i'], 2019, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'iX', variants: pack(['xDrive40', 'xDrive50'], 2022, CATALOG_YEAR_NOW, 5, 'Electric') },
    ],
  },
  {
    name: 'Mercedes-Benz',
    models: [
      { name: 'A-Class', variants: pack(['A 180', 'A 200', 'A 200d'], 2013, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'C-Class', variants: pack(['C 200', 'C 220d', 'C 300'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'E-Class', variants: pack(['E 200', 'E 220d', 'E 350d'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'S-Class', variants: pack(['S 350d', 'S 450', 'Maybach S 580'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'GLA', variants: pack(['GLA 200', 'GLA 220d'], 2014, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'GLC', variants: pack(['GLC 200', 'GLC 220d', 'GLC 300'], 2016, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'GLE', variants: pack(['GLE 300d', 'GLE 450', 'GLE 450d'], 2015, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'GLS', variants: pack(['GLS 450d', 'Maybach GLS 600'], 2016, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'EQA', variants: pack(['EQA 250+'], 2024, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'EQB', variants: pack(['EQB 350 4MATIC'], 2022, CATALOG_YEAR_NOW, 7, 'Electric') },
    ],
  },
  {
    name: 'Audi',
    models: [
      { name: 'A3', variants: pack(['35 TFSI', '40 TFSI'], 2014, 2020) },
      { name: 'A4', variants: pack(['30 TFSI', '40 TFSI', '40 TDI'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'A6', variants: pack(['45 TFSI', '45 TDI'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Q3', variants: pack(['Premium', 'Technology', 'Sportback'], 2012, CATALOG_YEAR_NOW) },
      { name: 'Q5', variants: pack(['Premium', 'Technology', 'S line'], 2010, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Q7', variants: pack(['Premium Plus', 'Technology'], 2010, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'e-tron', variants: pack(['50', '55'], 2021, CATALOG_YEAR_NOW, 5, 'Electric') },
    ],
  },
  {
    name: 'BYD',
    models: [
      { name: 'e6', variants: pack(['Electric'], 2022, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Atto 3', variants: pack(['Dynamic', 'Premium', 'Special Edition'], 2022, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Seal', variants: pack(['Dynamic', 'Premium', 'Performance'], 2023, CATALOG_YEAR_NOW, 5, 'Electric') },
      { name: 'Sealion 7', variants: pack(['Premium', 'Performance'], 2025, CATALOG_YEAR_NOW, 5, 'Electric') },
    ],
  },
  {
    name: 'Volvo',
    models: [
      { name: 'XC40', variants: pack(['B4 Ultimate', 'Recharge'], 2020, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'XC60', variants: pack(['B5 Ultimate', 'T8 Recharge'], 2015, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'XC90', variants: pack(['B5 Ultimate', 'T8 Recharge'], 2015, CATALOG_YEAR_NOW, 7, 'Hybrid') },
      { name: 'S90', variants: pack(['B5 Ultimate'], 2017, CATALOG_YEAR_NOW, 5, 'Hybrid') },
    ],
  },
  {
    name: 'Lexus',
    models: [
      { name: 'ES', variants: pack(['300h', '300h Luxury'], 2017, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'NX', variants: pack(['350h', '450h+'], 2015, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'RX', variants: pack(['350h', '500h'], 2015, CATALOG_YEAR_NOW, 5, 'Hybrid') },
    ],
  },
  {
    name: 'MINI',
    models: [
      { name: 'Cooper', variants: pack(['3 Door', '5 Door', 'S', 'JCW'], 2011, CATALOG_YEAR_NOW, 4) },
      { name: 'Countryman', variants: pack(['Cooper D', 'Cooper S', 'JCW'], 2013, CATALOG_YEAR_NOW) },
    ],
  },
  {
    name: 'Jaguar',
    models: [
      { name: 'XE', variants: pack(['S', 'SE'], 2016, 2020, 5, 'Petrol/Diesel') },
      { name: 'XF', variants: pack(['S', 'SE', 'R-Dynamic'], 2012, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'F-Pace', variants: pack(['S', 'R-Dynamic S'], 2016, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
    ],
  },
  {
    name: 'Land Rover',
    models: [
      { name: 'Defender', variants: pack(['90', '110', '130'], 2020, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Discovery', variants: pack(['S', 'SE', 'HSE', 'Metropolitan'], 2015, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Discovery Sport', variants: pack(['S', 'SE', 'HSE'], 2015, CATALOG_YEAR_NOW, 7, 'Petrol/Diesel') },
      { name: 'Range Rover Evoque', variants: pack(['S', 'SE', 'HSE', 'Autobiography'], 2011, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Range Rover Velar', variants: pack(['S', 'SE', 'HSE', 'Autobiography'], 2018, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Range Rover Sport', variants: pack(['SE', 'HSE', 'Autobiography'], 2014, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
      { name: 'Range Rover', variants: pack(['SE', 'HSE', 'Autobiography', 'SV'], 2013, CATALOG_YEAR_NOW, 5, 'Petrol/Diesel') },
    ],
  },
  {
    name: 'Porsche',
    models: [
      { name: 'Macan', variants: pack(['Macan', 'Macan S', 'Macan GTS', 'Macan Turbo'], 2014, CATALOG_YEAR_NOW) },
      { name: 'Cayenne', variants: pack(['Cayenne', 'Cayenne S', 'Cayenne E-Hybrid', 'Turbo'], 2011, CATALOG_YEAR_NOW, 5, 'Hybrid') },
      { name: 'Taycan', variants: pack(['Taycan', '4S', 'Turbo'], 2021, CATALOG_YEAR_NOW, 5, 'Electric') },
    ],
  },
  {
    name: 'Force',
    models: [
      { name: 'Gurkha', variants: pack(['3-Door', '5-Door'], 2017, CATALOG_YEAR_NOW, 5, 'Diesel') },
      { name: 'Trax Cruiser', variants: pack(['9 STR', '10 STR', '12 STR'], 2018, CATALOG_YEAR_NOW, 8, 'Diesel') },
    ],
  },
  {
    name: 'Isuzu',
    models: [
      { name: 'D-Max', variants: pack(['S', 'Hi-Lander', 'V-Cross'], 2017, CATALOG_YEAR_NOW, 5, 'Diesel') },
      { name: 'mu-X', variants: pack(['4x2 AT', '4x4 AT'], 2017, CATALOG_YEAR_NOW, 7, 'Diesel') },
    ],
  },
  {
    name: 'Mitsubishi',
    models: [
      { name: 'Pajero Sport', variants: pack(['2.5 MT', '2.5 AT'], 2008, 2019, 7, 'Diesel') },
      { name: 'Outlander', variants: pack(['2.4', 'PHEV'], 2007, 2020, 7, 'Hybrid') },
    ],
  },
  {
    name: 'Fiat',
    models: [
      { name: 'Punto', variants: pack(['Active', 'Dynamic', 'Emotion', 'Abarth'], 2009, 2018, 5, 'Petrol/Diesel') },
      { name: 'Linea', variants: pack(['Active', 'Dynamic', 'Emotion', 'T-Jet'], 2009, 2016, 5, 'Petrol/Diesel') },
      { name: 'Avventura', variants: pack(['Active', 'Dynamic', 'Emotion'], 2014, 2018, 5, 'Petrol/Diesel') },
      { name: 'Urban Cross', variants: pack(['Active', 'Dynamic', 'Emotion'], 2017, 2018, 5, 'Petrol/Diesel') },
    ],
  },
  {
    name: 'Datsun',
    models: [
      { name: 'redi-GO', variants: pack(['D', 'A', 'T', 'T (O)'], 2016, 2022) },
      { name: 'GO', variants: pack(['D', 'A', 'T', 'T (O)'], 2014, 2022) },
      { name: 'GO+', variants: pack(['D', 'A', 'T', 'T (O)'], 2015, 2022, 7) },
    ],
  },
];

export function findBrand(name: string): CarBrand | undefined {
  return carBrands.find((b) => b.name === name);
}

export function findModel(brand: CarBrand | undefined, name: string): CarModel | undefined {
  return brand?.models.find((m) => m.name === name);
}

export function searchCatalog(query: string): { brand: string; model: string }[] {
  const q = query.trim().toLowerCase();
  if (q.length < 2) return [];
  const hits: { brand: string; model: string }[] = [];
  for (const brand of carBrands) {
    for (const model of brand.models) {
      const hay = `${brand.name} ${model.name}`.toLowerCase();
      if (hay.includes(q)) hits.push({ brand: brand.name, model: model.name });
    }
  }
  return hits.slice(0, 20);
}

export function parseMakeModel(makeModel?: string | null): { brand: string; model: string } | null {
  const text = makeModel?.trim();
  if (!text) return null;
  const brand = [...carBrands]
    .sort((a, b) => b.name.length - a.name.length)
    .find((item) => text === item.name || text.startsWith(`${item.name} `));
  if (!brand) return null;
  const rest = text.slice(brand.name.length).trim();
  const model = [...brand.models]
    .sort((a, b) => b.name.length - a.name.length)
    .find((item) => rest === item.name || rest.startsWith(`${item.name} `));
  return { brand: brand.name, model: model?.name ?? rest.split(/\s+/)[0] ?? brand.name };
}
