import { HomeSpotlight } from '@/src/models/types';

const tip = (
  id: string,
  category: string,
  title: string,
  body: string,
  extra: Partial<HomeSpotlight> = {},
): HomeSpotlight => ({ id, kind: 'tip', category, title, body, icon: extra.icon ?? 'lightbulb', ...extra });

const quote = (id: string, title: string, body: string): HomeSpotlight => ({
  id,
  kind: 'quote',
  title,
  body,
  author: 'Ride Buddy',
  icon: 'quote',
});

export const spotlightTips: HomeSpotlight[] = [
  tip('places', 'app', 'Save home & office', 'Add your usual places once — Ride Buddy uses them for faster matching and one-tap From / To.', { ctaLabel: 'Set places', ctaRoute: '/profile/places', icon: 'place' }),
  tip('share_ride', 'app', 'Share open rides', 'Empty seats? Share the ride on WhatsApp — coworkers on your corridor often join the same day.', { ctaLabel: 'Open Ride', ctaRoute: '/ride', icon: 'share' }),
  tip('need_post', 'app', 'Need a ride?', 'Post your trip once — matching open rides show up, and hosts on your route can offer a seat.', { ctaLabel: 'I need a ride', ctaRoute: '/ride/search', icon: 'hail' }),
  tip('comfort', 'app', 'Comfort vs standard', 'Comfort caps the back row at 2 seats. Offer it only if your car has 4+ seats.', { ctaLabel: 'My vehicles', ctaRoute: '/profile/vehicles', icon: 'airline-seat-recline-extra' }),
  tip('carpool_cash', 'app', 'Cash seat share', 'Ride Buddy is office carpool, not a taxi. Pay the shared seat amount in cash when you meet.', { icon: 'payments' }),
  tip('full_address', 'app', 'Short name vs full address', 'Others see a short area label by default. Tap “Full address” anytime you need the exact pin.'),
  tip('my_location', 'app', 'Use My location', 'On From, tap My location to fill your current spot — great when you’re already heading out.', { icon: 'place' }),
  tip('profile_strength', 'app', 'Complete your profile', 'Work, places, and interests make matching and posts clearer for co-riders who don’t know you yet.', { ctaLabel: 'Profile', ctaRoute: '/profile' }),
  tip('verify_meet', 'safety', 'Confirm before you go', 'Match the host name, car, and meet point in the app before you get in — don’t share rides with strangers off-app.', { icon: 'shield' }),
  tip('share_trip', 'safety', 'Tell someone you’re riding', 'Share your trip details with a friend or family when you’re on a new route or late evening commute.', { icon: 'shield' }),
  tip('seatbelt', 'safety', 'Belt up every time', 'Hosts and co-riders: seatbelts aren’t optional. A calm commute starts with everyone secured.', { icon: 'shield' }),
  tip('night_meet', 'safety', 'Meet in well-lit spots', 'Prefer office gates, metro exits, or busy corners over dark side streets — especially after sunset.', { icon: 'shield' }),
  tip('cash_open', 'safety', 'Settle fare openly', 'Agree the seat share in the app, then pay cash in the open at the meet point or drop — no off-record deals.', { icon: 'payments' }),
  tip('on_time', 'manners', 'Be on time', 'A few minutes late can ripple for everyone. Message early if you’re stuck — don’t ghost the pin.', { icon: 'schedule' }),
  tip('quiet_option', 'manners', 'Ask before loud calls', 'Speakerphone and long calls can spoil a commute. Ask first, or keep it short and headphones-only.', { icon: 'chat' }),
  tip('food_scent', 'manners', 'Go easy on strong food', 'Strong-smelling snacks stay in a closed car. Keep messy or heavy-scent meals for after the ride.', { icon: 'chat' }),
  tip('space', 'manners', 'Respect personal space', 'Bags in your lap or boot if offered — don’t sprawl into the next seat without asking.', { icon: 'chat' }),
  tip('thank_host', 'manners', 'Thank the host', 'A quick thanks at drop-off goes far. Regular co-riders become the rides you can count on.', { icon: 'chat' }),
  tip('respect_host', 'manners', 'Respect the host', 'They’re sharing their car and route — not running a service. Be considerate with doors, seats, and the music they’re playing.', { icon: 'chat' }),
  tip('not_a_taxi', 'manners', 'They’re your host', 'Skip taxi talk — no “cab”, “driver”, or “drop me”. Say host, co-rider, meet point, and seat share. It’s carpool, not a cab.', { icon: 'chat' }),
  tip('cancel_early', 'manners', 'Cancel early if plans change', 'Free the seat as soon as you know — last-minute no-shows leave others stranded.', { icon: 'schedule' }),
  tip('interests', 'connect', 'Show a few interests', 'Top interests appear on posts — easy icebreakers for people who share your commute.', { ctaLabel: 'Interests', ctaRoute: '/profile/interests', icon: 'connect' }),
  tip('small_talk', 'connect', 'Chat is optional', 'Some riders want quiet; some want chat. Start light, and follow their energy — silence is fine too.', { icon: 'connect' }),
  tip('shared_route', 'connect', 'Same corridor, regular rides', 'If the trip went well, ask about repeating tomorrow — regular carpools beat one-off searches.', { icon: 'connect' }),
  tip('work_line', 'connect', 'Role & company on posts', 'A clear work line helps co-riders trust they’re joining office carpool, not a random lift.', { ctaLabel: 'Work profile', ctaRoute: '/profile/work', icon: 'connect' }),
  tip('new_coworker', 'connect', 'First ride with someone new', 'Introduce yourself once, keep the first trip light, and stick to the agreed meet point — trust builds trip by trip.', { icon: 'connect' }),
];

export const spotlightQuotes: HomeSpotlight[] = [
  quote('q_together', 'Shared road', 'The best journeys are shared — even the short ones to the office.'),
  quote('q_kindness', 'Small kindness', 'A seat offered, a thanks given — kindness travels farther than any shortcut.'),
  quote('q_consistency', 'Show up', 'Consistency builds trust. Be the co-rider others look forward to seeing.'),
  quote('q_team', 'Team commute', 'Carpool isn’t just a ride — it’s a tiny team getting everyone to work on time.'),
  quote('q_quiet', 'Quiet mornings', 'Sometimes the kindest thing on a commute is comfortable silence.'),
  quote('q_start', 'Start the day right', 'How you treat people before 9 a.m. sets the tone for the rest of the day.'),
  quote('q_share', 'Share the load', 'One empty seat is an invitation. Filling it is community.'),
  quote('q_patience', 'Patience', 'Traffic will test you. Your co-riders shouldn’t have to.'),
  quote('q_respect', 'Respect', 'Respect the car, the time, and the person who made space for you.'),
  quote('q_again', 'See you tomorrow', 'The best carpools aren’t one-offs — they’re habits built with good people.'),
  quote('q_safe', 'Arrive safe', 'Getting there together means getting there safely — every time.'),
  quote('q_hello', 'Say hello', 'A warm hello costs nothing and can turn a stranger into a regular ride.'),
  quote('q_office', 'Office family', 'Colleagues on the road become the friends who make Mondays lighter.'),
  quote('q_fuel', 'Shared cost', 'Sharing a seat is sharing fuel, time, and a little bit of goodwill.'),
];

export function spotlightById(id: string): HomeSpotlight | undefined {
  return spotlightTips.find((t) => t.id === id) ?? spotlightQuotes.find((q) => q.id === id);
}
