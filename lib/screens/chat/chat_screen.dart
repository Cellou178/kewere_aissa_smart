import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  List _cycles = [];
  List _donnees = [];
  List _stocks = [];
  bool _dataLoaded = false;

  // Suggestions rapides
  final List<Map<String, String>> _suggestions = [
    {'icon': '🐔', 'text': 'Analyse mes cycles actifs'},
    {'icon': '💀', 'text': 'Quel est mon taux de mortalité ?'},
    {'icon': '🌡️', 'text': 'Conseils température aujourd\'hui'},
    {'icon': '💰', 'text': 'Estimation revenus ce mois'},
    {'icon': '📦', 'text': 'État de mes stocks'},
    {'icon': '🔮', 'text': 'Prédictions prochaines semaines'},
    {'icon': '🌾', 'text': 'Optimiser l\'alimentation'},
    {'icon': '💊', 'text': 'Protocole vaccination'},
  ];

  @override
  void initState() {
    super.initState();
    _addMessage(
        role: 'assistant',
        text: '''Bonjour ${SessionManager.prenomNom} 👋 ! Je suis votre assistant avicole IA.

Je peux vous aider avec :
🐔 Analyse de vos élevages
📊 Interprétation des données
💡 Conseils et recommandations
🔮 Prédictions et tendances
💰 Calculs financiers

Posez-moi n\'importe quelle question sur votre ferme !''');
    _loadData();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ApiService.getCycles(),
      ApiService.getDonnees(),
      ApiService.getStocks(),
    ]);
    setState(() {
      _cycles = results[0] is List ? results[0] as List : [];
      _donnees = results[1] is List ? results[1] as List : [];
      _stocks = results[2] is List ? results[2] as List : [];
      _dataLoaded = true;
    });
  }

  void _addMessage({required String role, required String text,
    bool isLoading = false}) {
    setState(() => _messages.add({
      'role': role,
      'text': text,
      'time': DateTime.now(),
      'isLoading': isLoading,
    }));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  String _buildContexte() {
    final cyclesActifs = _cycles.where((c) =>
    c['statut'] == 'actif' || c['statut'] == 'en_cours').toList();
    final totalPoulets = _cycles.fold<int>(0, (s, c) =>
    s + ((c['nombre_sujets'] ?? 0) as num).toInt());
    final totalMorts = _donnees.fold<int>(0, (s, d) =>
    s + ((d['mortalite'] ?? 0) as num).toInt());
    final tauxMort = totalPoulets > 0
        ? (totalMorts / totalPoulets * 100).toStringAsFixed(1) : '0';
    final avgTemp = _donnees.isEmpty ? 0 :
    (_donnees.fold<double>(0, (s, d) =>
    s + ((d['temperature'] ?? 0) as num).toDouble()) /
        _donnees.length).toStringAsFixed(1);
    final stocksAlerte = _stocks.where((s) {
      final qte = ((s['quantite'] ?? 0) as num).toDouble();
      final seuil = ((s['seuil_alerte'] ?? 0) as num).toDouble();
      return qte <= seuil;
    }).length;

    return '''CONTEXTE FERME DE ${SessionManager.nom.toUpperCase()}:
- Rôle: ${SessionManager.role}
- Total cycles: ${_cycles.length} (${cyclesActifs.length} actifs)
- Poulets total: $totalPoulets
- Mortalité totale: $totalMorts ($tauxMort%)
- Température moyenne: $avgTemp°C
- Relevés enregistrés: ${_donnees.length}
- Stocks en alerte: $stocksAlerte/${_stocks.length}
- Cycles actifs: ${cyclesActifs.map((c) => '${c['nom']} (${c['nombre_sujets']} sujets, ${c['souche'] ?? ''})').join(', ')}''';
  }

  Future<void> _envoyer([String? texteRapide]) async {
    final texte = texteRapide ?? _msgCtrl.text.trim();
    if (texte.isEmpty || _loading) return;

    _msgCtrl.clear();
    _addMessage(role: 'user', text: texte);
    setState(() => _loading = true);

    // Message de chargement
    _addMessage(role: 'assistant', text: '...', isLoading: true);

    try {
      final history = _messages
          .where((m) => !(m['isLoading'] as bool? ?? false) && m['text'] != '...')
          .take(_messages.length - 1)
          .map((m) => {
            'role': m['role'] as String,
            'content': m['text'] as String,
          }).toList();

      final reply = await ApiService.callChat(
        texte,
        history: history,
        contexte: _buildContexte(),
      );
      setState(() => _messages.removeWhere((m) => m['isLoading'] == true));
      _addMessage(role: 'assistant', text: reply.isEmpty
          ? '❌ Réponse vide. Réessayez.' : reply);
    } catch (e) {
      setState(() => _messages.removeWhere((m) => m['isLoading'] == true));
      _addMessage(role: 'assistant',
          text: '❌ Connexion impossible. Vérifiez votre réseau.');
    }
    setState(() => _loading = false);
  }

  void _effacerHistorique() {
    setState(() {
      _messages.clear();
      _addMessage(role: 'assistant',
          text: 'Conversation effacée. Comment puis-je vous aider ?');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F),
                Color(0xFF4C1D95)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🤖',
                  style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kewere IA', style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w900)),
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_dataLoaded ? 'En ligne • Données chargées'
                    : 'Chargement des données...',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
              ]),
            ])),
            // Statut messages
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_messages.length} msgs',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10)),
            ),
            IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white54, size: 20),
                onPressed: _effacerHistorique),
          ]),
        ),

        // Messages
        Expanded(child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          itemCount: _messages.length,
          itemBuilder: (_, i) => _buildMessage(_messages[i]),
        )),

        // Suggestions (si peu de messages)
        if (_messages.length <= 2) _buildSuggestions(),

        // Input
        _buildInput(),
      ]),
    );
  }

  Widget _buildMessage(Map m) {
    final isUser = m['role'] == 'user';
    final isLoading = m['isLoading'] == true;
    final time = m['time'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4C1D95), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('🤖',
                  style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: isUser ? kBlue : Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6)]),
                child: isLoading
                    ? _typingIndicator()
                    : SelectableText(
                    m['text'] as String,
                    style: TextStyle(
                        color: isUser ? Colors.white
                            : const Color(0xFF1E293B),
                        fontSize: 13, height: 1.5)),
              ),
              const SizedBox(height: 3),
              Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 9)),
            ],
          )),

          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: kBlue.withOpacity(0.2),
              child: Text(SessionManager.initialesNom,
                  style: const TextStyle(color: kBlue,
                      fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingIndicator() => SizedBox(
    width: 40, height: 20,
    child: Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) =>
            _dot(i * 200))),
  );

  Widget _dot(int delayMs) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 600 + delayMs),
    builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6, height: 6,
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.4 + v * 0.6),
            shape: BoxShape.circle)),
  );

  Widget _buildSuggestions() => Container(
    height: 90,
    margin: const EdgeInsets.only(bottom: 4),
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: _suggestions.map((s) => GestureDetector(
        onTap: () => _envoyer(s['text']),
        child: Container(
          margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBlue.withOpacity(0.2)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6)]),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s['icon']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            SizedBox(width: 80, child: Text(s['text']!,
                style: const TextStyle(
                    color: kBlue, fontSize: 9,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center, maxLines: 2,
                overflow: TextOverflow.ellipsis)),
          ]),
        ),
      )).toList(),
    ),
  );

  Widget _buildInput() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, -2))]),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _msgCtrl,
            maxLines: 3, minLines: 1,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
                hintText: 'Posez une question sur votre élevage...',
                hintStyle: TextStyle(
                    color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    vertical: 10)),
            onSubmitted: (_) => _envoyer(),
            textInputAction: TextInputAction.send,
          )),
          // Bouton suggestions
          IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded,
                  color: Colors.grey, size: 20),
              onPressed: () => setState(() {}),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          const SizedBox(width: 8),
        ]),
      )),
      const SizedBox(width: 8),
      // Bouton envoyer
      GestureDetector(
        onTap: () => _envoyer(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: _loading
                      ? [Colors.grey, Colors.grey.shade400]
                      : [kBlue, kBlueLight]),
              borderRadius: BorderRadius.circular(22),
              boxShadow: _loading ? [] : [BoxShadow(
                  color: kBlue.withOpacity(0.4), blurRadius: 8)]),
          child: Center(child: _loading
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded,
              color: Colors.white, size: 18)),
        ),
      ),
    ]),
  );
}