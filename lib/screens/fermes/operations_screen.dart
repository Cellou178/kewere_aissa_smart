import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class OperationsScreen extends StatefulWidget {
  final Map ferme;
  final List cycles;
  const OperationsScreen({super.key, required this.ferme, required this.cycles});
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  String? _selectedCycleId;
  bool _loading = false;
  String _error = '';
  DateTime _dateReleve = DateTime.now();
  final _mortCtrl = TextEditingController();
  final _vendusCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  final _g1Ctrl = TextEditingController();
  final _g2Ctrl = TextEditingController();
  final _g3Ctrl = TextEditingController();
  final _g4Ctrl = TextEditingController();
  final _g5Ctrl = TextEditingController();
  final _tempMatinCtrl = TextEditingController();
  final _tempSoirCtrl = TextEditingController();
  final _humValCtrl = TextEditingController();
  final _alimentConsoCtrl = TextEditingController();
  final _alimentRestCtrl = TextEditingController();
  final _sacsRestCtrl = TextEditingController();
  final _commentaireCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  String? _tempStandard;
  String? _humStandard;
