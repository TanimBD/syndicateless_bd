import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/widgets.dart';
import '../data/sectors.dart';
import '../database_helper.dart';

class ReportFormPage extends StatefulWidget {
  final String? sectorId;
  final String? issueType; // English label
  final String? prefillDescription;
  final double? prefillAmount;
  const ReportFormPage({super.key, this.sectorId, this.issueType, this.prefillDescription, this.prefillAmount});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _sector = widget.sectorId ?? 'transport';
  late String? _issue = widget.issueType;
  String? _district;
  final _place = TextEditingController();
  late final _desc = TextEditingController(text: widget.prefillDescription ?? '');
  late final _amount = TextEditingController(
      text: widget.prefillAmount == null ? '' : widget.prefillAmount!.toStringAsFixed(0));
  bool _anonymous = true;
  Uint8List? _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _district = context.read<AppState>().user?.district;
  }

  Future<void> _pickImage(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1000, maxHeight: 1000, imageQuality: 45);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (bytes.length > 600 * 1024) {
      if (mounted) showSnack(context, context.tr('ছবিটি অনেক বড়', 'Image is too large'), error: true);
      return;
    }
    setState(() => _image = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issue == null) {
      showSnack(context, context.tr('অভিযোগের ধরন নির্বাচন করুন', 'Select the type of issue'), error: true);
      return;
    }
    final user = context.read<AppState>().user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final code = await DatabaseHelper.instance.submitReport(
        sector: _sector,
        issueType: _issue!,
        district: _district!,
        place: _place.text.trim(),
        description: _desc.text.trim(),
        amount: double.tryParse(_amount.text) ?? 0,
        anonymous: _anonymous,
        user: user,
        imageBase64: _image == null ? null : base64Encode(_image!),
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: Text(ctx.t('অভিযোগ জমা হয়েছে', 'Report submitted')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ctx.t('আপনার ট্র্যাকিং কোড:', 'Your tracking code:')),
            const SizedBox(height: 8),
            SelectableText(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(
                ctx.t('এই কোড দিয়ে যেকোনো সময় অভিযোগের অবস্থা দেখতে পারবেন।',
                    'Use this code to check the status of your report anytime.'),
                textAlign: TextAlign.center),
          ]),
          actions: [
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              icon: const Icon(Icons.copy),
              label: Text(ctx.t('কপি', 'Copy')),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t('ঠিক আছে', 'OK'))),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, context.tr('জমা দেওয়া যায়নি: $e', 'Could not submit: $e'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sector = sectorById(_sector);
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: Text(context.t('সিন্ডিকেট/দুর্নীতির অভিযোগ', 'Report a syndicate'))),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<String>(
            value: _sector,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.t('খাত', 'Sector'), prefixIcon: Icon(sector.icon, color: sector.color)),
            items: kSectors
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name.of(context.isBn))))
                .toList(),
            onChanged: (v) => setState(() {
              _sector = v!;
              _issue = null;
            }),
          ),
          gap,
          Text(context.t('অভিযোগের ধরন', 'Type of issue'), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sector.issueTypes
                .map((t) => ChoiceChip(
                      label: Text(t.of(context.isBn)),
                      selected: _issue == t.en,
                      onSelected: (_) => setState(() => _issue = t.en),
                    ))
                .toList(),
          ),
          gap,
          DistrictField(value: _district, onChanged: (v) => setState(() => _district = v)),
          gap,
          TextFormField(
            controller: _place,
            decoration: InputDecoration(
              labelText: context.t('স্থান / প্রতিষ্ঠান / রুট', 'Place / institution / route'),
              hintText: context.t('যেমন: গাবতলী বাস টার্মিনাল', 'e.g. Gabtoli bus terminal'),
              prefixIcon: const Icon(Icons.place_outlined),
            ),
            validator: (v) => (v ?? '').trim().length < 3 ? context.tr('স্থান লিখুন', 'Enter the place') : null,
          ),
          gap,
          TextFormField(
            controller: _desc,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: context.t('কী ঘটেছে? (বিস্তারিত)', 'What happened? (details)'),
              alignLabelWithHint: true,
              hintText: context.t('কে, কখন, কত টাকা, কীভাবে — যত বিস্তারিত তত ভালো',
                  'Who, when, how much, how — more detail helps'),
            ),
            validator: (v) =>
                (v ?? '').trim().length < 15 ? context.tr('কমপক্ষে ১৫ অক্ষরে লিখুন', 'Write at least 15 characters') : null,
          ),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.t('দাবিকৃত/অতিরিক্ত টাকা (ঐচ্ছিক)', 'Money demanded / overcharged (optional)'),
              prefixIcon: const Icon(Icons.payments_outlined),
              prefixText: '৳ ',
            ),
          ),
          gap,
          Text(context.t('প্রমাণ (ছবি, ঐচ্ছিক)', 'Evidence (photo, optional)'), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          if (_image != null)
            Stack(children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_image!, height: 180, width: double.infinity, fit: BoxFit.cover)),
              Positioned(
                right: 6,
                top: 6,
                child: IconButton.filled(onPressed: () => setState(() => _image = null), icon: const Icon(Icons.close)),
              ),
            ])
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: Text(context.t('ক্যামেরা', 'Camera')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(context.t('গ্যালারি', 'Gallery')),
                ),
              ),
            ]),
          gap,
          Card(
            child: SwitchListTile(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              secondary: const Icon(Icons.privacy_tip_outlined),
              title: Text(context.t('পরিচয় গোপন রাখুন', 'Keep me anonymous')),
              subtitle: Text(context.t('আপনার নাম ও নম্বর প্রকাশ্যে দেখানো হবে না।', 'Your name and number are not shown publicly.')),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('অভিযোগ যাবে: ${sector.authority.bn}', 'Routed to: ${sector.authority.en}'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(context.t('অভিযোগ জমা দিন', 'Submit report')),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
