// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/event_model.dart';
//
// class CreateEventScreen extends StatefulWidget {
//   const CreateEventScreen({super.key});
//
//   @override
//   State<CreateEventScreen> createState() => _CreateEventScreenState();
// }
//
// class _CreateEventScreenState extends State<CreateEventScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final titleCtrl = TextEditingController();
//   final descCtrl = TextEditingController();
//   final locationCtrl = TextEditingController();
//
//   String selectedCategory = 'Tech';
//   String selectedEventType = 'Online';
//
//   DateTime? startDate;
//   TimeOfDay? startTime;
//   DateTime? endDate;
//   TimeOfDay? endTime;
//
//   bool isFreeEvent = true;
//
//   File? bannerImage; // 🔥 USER SELECTED IMAGE
//
//   final categories = [
//     'Tech',
//     'Business',
//     'Networking',
//     'Workshop',
//     'Conference',
//     'Summit',
//   ];
//
//   @override
//   void dispose() {
//     titleCtrl.dispose();
//     descCtrl.dispose();
//     locationCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0B1220),
//       appBar: AppBar(
//         title: const Text('Create Event'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _bannerPicker(),
//
//                 _section('Basic Info'),
//                 _card([
//                   _field('Event Title', titleCtrl),
//                   _field('Description', descCtrl, maxLines: 3),
//                   _field('Location', locationCtrl),
//                 ]),
//
//                 _section('Category'),
//                 _card([
//                   Wrap(
//                     spacing: 10,
//                     runSpacing: 10,
//                     children: categories
//                         .map((c) => _chip(
//                       c,
//                       selectedCategory == c,
//                           () => setState(() => selectedCategory = c),
//                     ))
//                         .toList(),
//                   ),
//                 ]),
//
//                 _section('Event Type'),
//                 _card([
//                   Row(
//                     children: [
//                       _chip(
//                         'Online',
//                         selectedEventType == 'Online',
//                             () => setState(() => selectedEventType = 'Online'),
//                       ),
//                       const SizedBox(width: 12),
//                       _chip(
//                         'In-person',
//                         selectedEventType == 'In-person',
//                             () => setState(() => selectedEventType = 'In-person'),
//                       ),
//                     ],
//                   ),
//                 ]),
//
//                 _section('Date & Time'),
//                 _card([
//                   _dateTimeRow(
//                     'Start',
//                     startDate,
//                     startTime,
//                     onDateTap: () async {
//                       final d = await _pickDate();
//                       if (d != null) setState(() => startDate = d);
//                     },
//                     onTimeTap: () async {
//                       final t = await _pickTime();
//                       if (t != null) setState(() => startTime = t);
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _dateTimeRow(
//                     'End',
//                     endDate,
//                     endTime,
//                     onDateTap: () async {
//                       final d = await _pickDate();
//                       if (d != null) setState(() => endDate = d);
//                     },
//                     onTimeTap: () async {
//                       final t = await _pickTime();
//                       if (t != null) setState(() => endTime = t);
//                     },
//                   ),
//                 ]),
//
//                 _section('Pricing'),
//                 _card([
//                   SwitchListTile(
//                     contentPadding: EdgeInsets.zero,
//                     value: isFreeEvent,
//                     onChanged: (v) => setState(() => isFreeEvent = v),
//                     title: const Text(
//                       'Free Event',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     activeColor: const Color(0xFF6366F1),
//                   ),
//                 ]),
//
//                 const SizedBox(height: 24),
//
//                 SizedBox(
//                   width: double.infinity,
//                   height: 54,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF6366F1),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     onPressed: _createEvent,
//                     child: const Text(
//                       'Create Event',
//                       style:
//                       TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ================= BANNER PICKER =================
//
//   Widget _bannerPicker() {
//     return GestureDetector(
//       onTap: _pickBanner,
//       child: Container(
//         height: 190,
//         margin: const EdgeInsets.only(bottom: 20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(22),
//           image: DecorationImage(
//             image: bannerImage != null
//                 ? FileImage(bannerImage!)
//                 : const AssetImage('lib/images/event_placeholder.jpg')
//             as ImageProvider,
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(22),
//             gradient: LinearGradient(
//               begin: Alignment.bottomCenter,
//               end: Alignment.topCenter,
//               colors: [
//                 Colors.black.withOpacity(0.6),
//                 Colors.transparent,
//               ],
//             ),
//           ),
//           child: const Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: EdgeInsets.all(12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.camera_alt, color: Colors.white),
//                   SizedBox(width: 8),
//                   Text(
//                     'Add Event Banner',
//                     style: TextStyle(
//                         color: Colors.white, fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _pickBanner() async {
//     final picker = ImagePicker();
//     final XFile? file =
//     await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
//
//     if (file != null) {
//       setState(() => bannerImage = File(file.path));
//     }
//   }
//
//   // ================= HELPERS =================
//
//   Widget _section(String title) => Padding(
//     padding: const EdgeInsets.only(bottom: 10, top: 16),
//     child: Text(
//       title,
//       style: const TextStyle(
//         color: Colors.white70,
//         fontSize: 15,
//         fontWeight: FontWeight.w600,
//       ),
//     ),
//   );
//
//   Widget _card(List<Widget> children) => Container(
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: const Color(0xFF111827),
//       borderRadius: BorderRadius.circular(18),
//       border: Border.all(color: Colors.white10),
//     ),
//     child: Column(children: children),
//   );
//
//   Widget _field(String label, TextEditingController controller,
//       {int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: TextFormField(
//         controller: controller,
//         maxLines: maxLines,
//         validator: (v) => v == null || v.isEmpty ? 'Required' : null,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.white70),
//           filled: true,
//           fillColor: const Color(0xFF1F2937),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _chip(String label, bool selected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected ? const Color(0xFF6366F1) : const Color(0xFF1F2937),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Text(label, style: const TextStyle(color: Colors.white)),
//       ),
//     );
//   }
//
//   Widget _dateTimeRow(
//       String label,
//       DateTime? date,
//       TimeOfDay? time, {
//         required VoidCallback onDateTap,
//         required VoidCallback onTimeTap,
//       }) {
//     return Row(
//       children: [
//         Expanded(
//           child: _dateTimeBox(
//             date == null
//                 ? '$label Date'
//                 : '${date.day}/${date.month}/${date.year}',
//             Icons.calendar_today,
//             onDateTap,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _dateTimeBox(
//             time == null ? 'Time' : time.format(context),
//             Icons.access_time,
//             onTimeTap,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _dateTimeBox(
//       String value, IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1F2937),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.white70, size: 18),
//             const SizedBox(width: 10),
//             Text(value, style: const TextStyle(color: Colors.white)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<DateTime?> _pickDate() {
//     return showDatePicker(
//       context: context,
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2035),
//       initialDate: DateTime.now(),
//     );
//   }
//
//   Future<TimeOfDay?> _pickTime() {
//     return showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//   }
//
//   // ================= CREATE EVENT =================
//
//   void _createEvent() {
//     if (!_formKey.currentState!.validate()) return;
//     if (startDate == null ||
//         startTime == null ||
//         endDate == null ||
//         endTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select date & time')),
//       );
//       return;
//     }
//
//     // final event = EventModel(
//     //   title: titleCtrl.text.trim(),
//     //   description: descCtrl.text.trim(),
//     //   location: locationCtrl.text.trim(),
//     //   category: selectedCategory,
//     //   eventType: selectedEventType,
//     //   startTimeDt:
//     //   '${startTimeDt!.day}/${startTimeDt!.month}/${startTimeDt!.year}',
//     //   startTime: startTime!.format(context),
//     //   endDate: '${endDate!.day}/${endDate!.month}/${endDate!.year}',
//     //   endTime: endTime!.format(context),
//     //   image: bannerImage?.path ?? 'lib/images/event_placeholder.jpg',
//     //   isFree: isFreeEvent,
//     // );
//
//     final event = EventModel(
//       title: titleCtrl.text.trim(),
//       description: descCtrl.text.trim(),
//       eventType: selectedEventType,
//
//       location: selectedEventType == 'InPerson'
//           ? locationCtrl.text.trim()
//           : null,
//
//       virtualLink: selectedEventType == 'Online'
//           ? virtualLinkCtrl.text.trim()
//           : null,
//
//       startTimeDt: startTimeDt!,        // DateTime
//       endTimeDt: endTimeDt!,            // DateTime
//
//       bannerUrl: bannerImage?.path,     // String?
//
//       waitlistEnabled: isWaitlistEnabled,
//       registrationDeadline: registrationDeadline!, // DateTime
//
//       category: selectedCategory,
//       isFree: isFreeEvent,
//
//       createdByMe: true,
//     );
//
//     Navigator.pop(context, event);
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// /*import 'package:flutter/material.dart';
//
// class CreateEventScreen extends StatefulWidget {
//   const CreateEventScreen({super.key});
//
//   @override
//   State<CreateEventScreen> createState() => _CreateEventScreenState();
// }
//
// class _CreateEventScreenState extends State<CreateEventScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   DateTime? selectedDateTime;
//
//   Future<void> _pickDateTime() async {
//     final date = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(data: ThemeData.dark(), child: child!);
//       },
//     );
//
//     if (date == null) return;
//
//     final time = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//       builder: (context, child) {
//         return Theme(data: ThemeData.dark(), child: child!);
//       },
//     );
//
//     if (time == null) return;
//
//     setState(() {
//       selectedDateTime = DateTime(
//         date.year,
//         date.month,
//         date.day,
//         time.hour,
//         time.minute,
//       );
//     });
//   }
//
//   /// ✅ SAFE EXIT METHOD
//   void _closeScreen() {
//     if (Navigator.canPop(context)) {
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         _closeScreen();
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFF0B1220),
//         appBar: AppBar(
//           backgroundColor: const Color(0xFF0B1220),
//           elevation: 0,
//           title: const Text("Create New Event"),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: _closeScreen,
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _closeScreen,
//             ),
//           ],
//         ),
//         body: SafeArea(
//           child: Form(
//             key: _formKey,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _sectionTitle("Event Banner"),
//                   _bannerUpload(),
//
//                   const SizedBox(height: 20),
//                   _sectionTitle("Event Name"),
//                   _inputField(hint: "Enter event name", icon: Icons.title),
//
//                   const SizedBox(height: 20),
//                   _sectionTitle("Date and Time"),
//                   _dateTimePicker(),
//
//                   const SizedBox(height: 20),
//                   _sectionTitle("Description"),
//                   _inputField(
//                     hint: "Enter event description",
//                     maxLines: 4,
//                   ),
//
//                   const SizedBox(height: 20),
//                   _sectionTitle("Payments"),
//                   _inputField(
//                     hint: "Enter payment details",
//                     icon: Icons.payment,
//                   ),
//
//                   const SizedBox(height: 20),
//                   _sectionTitle("Limited Members"),
//                   _inputField(
//                     hint: "Enter maximum number of attendees",
//                     icon: Icons.numbers,
//                     keyboardType: TextInputType.number,
//                   ),
//
//                   const SizedBox(height: 30),
//                   _actions(),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ================= UI COMPONENTS =================
//
//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   Widget _bannerUpload() {
//     return Container(
//       height: 120,
//       decoration: BoxDecoration(
//         color: const Color(0xFF1F2937),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Center(
//         child: OutlinedButton.icon(
//           onPressed: () {},
//           icon: const Icon(Icons.upload, color: Color(0xFF7C83FF)),
//           label: const Text(
//             "Upload Banner",
//             style: TextStyle(color: Color(0xFF7C83FF)),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _inputField({
//     required String hint,
//     IconData? icon,
//     int maxLines = 1,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFF1F2937),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextFormField(
//         maxLines: maxLines,
//         keyboardType: keyboardType,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           prefixIcon: icon != null
//               ? Icon(icon, color: Colors.white54)
//               : null,
//           hintText: hint,
//           hintStyle: const TextStyle(color: Colors.white54),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.all(14),
//         ),
//       ),
//     );
//   }
//
//   Widget _dateTimePicker() {
//     return GestureDetector(
//       onTap: _pickDateTime,
//       child: Container(
//         height: 52,
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1F2937),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.calendar_today, color: Colors.white54),
//             const SizedBox(width: 12),
//             Text(
//               selectedDateTime == null
//                   ? "dd-mm-yyyy --:--"
//                   : selectedDateTime.toString(),
//               style: const TextStyle(color: Colors.white54),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _actions() {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: _closeScreen,
//             child: const Text("Cancel"),
//           ),
//         ),
//         const SizedBox(width: 14),
//         Expanded(
//           child: ElevatedButton(
//             onPressed: () {
//               if (_formKey.currentState!.validate()) {
//                 // submit event logic
//                 _closeScreen();
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF7C83FF),
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text("Create Event"),
//           ),
//         ),
//       ],
//     );
//   }
// }*/