// ── APP BAR ──
appBar: AppBar(

backgroundColor: const Color(0xFF0F172A),

foregroundColor: Colors.white,

elevation: 0,

title: const Text(
'Kewere Smart',
style: TextStyle(
fontWeight: FontWeight.w800,
),
),

actions: [

// Notifications
Stack(
children: [

IconButton(
icon: const Icon(
Icons.notifications_outlined,
color: Colors.white,
),
onPressed: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const NotificationsScreen(),
),
),
),

if (NotificationService.nonLues > 0)
Positioned(
top: 8,
right: 8,
child: Container(

padding: const EdgeInsets.all(3),

decoration: const BoxDecoration(
color: Colors.redAccent,
shape: BoxShape.circle,
),

child: Text(
'${NotificationService.nonLues}',

style: const TextStyle(
color: Colors.white,
fontSize: 8,
fontWeight: FontWeight.w800,
),
),
),
),
],
),

// Badge rôle
Container(

margin: const EdgeInsets.only(right: 12),

padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 3,
),

decoration: BoxDecoration(

color: Colors.green.withOpacity(0.25),

borderRadius:
BorderRadius.circular(20),
),

child: Row(
children: [

const CircleAvatar(
radius: 3,
backgroundColor: Colors.greenAccent,
),

const SizedBox(width: 4),

Text(
SessionManager.role.toUpperCase(),

style: const TextStyle(
color: Colors.white,
fontSize: 9,
fontWeight: FontWeight.w700,
),
),
],
),
),
],
),