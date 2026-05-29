import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/app_constants.dart';
import '../managers/session_manager.dart';

class NotificationService {
  // ── Notifications locales (in-app) ──
  static final List<Map<String, dynamic>> _notifications = [];
  static final List<Function(Map)> _listeners = [];

  static List<Map<String, dynamic>> get notifications => _notifications;
  static int get nonLues => _notifications.where((n) => !n['lu']).length;

  static void addListener(Function(Map) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(Map) listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners(Map notification) {
    for (final l in _listeners) l(notification);
  }

  // Ajouter une notification
  static void add({
    required String titre,
    required String message,
    String type = 'info', // info, warning, danger, success
    String? action,
    Map? data,
  }) {
    final notif = {
      'id': DateTime.now.toString(),
      'titre': titre,
      'message': message,
      'type': type,
      'action': action,
      'data': data,
      'date': DateTime.now().toIso8601String(),
      'lu': false,
    };
    _notifications.insert(0, notif);
    _notifyListeners(notif);
  }

  static void marquerLu(String id) {
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx >= 0) _notifications[idx]['lu'] = true;
  }

  static void marquerToutLu() {
    for (final n in _notifications) n['lu'] = true;
  }

  static void supprimer(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
  }

  static void supprimerTout() => _notifications.clear();

  // ── Vérifier alertes automatiques ──
  static void verifierAlertes({
    required List donnees,
    required List stocks,
    required List cycles,
  }) {
    // Alertes mortalité
    if (donnees.isNotEmpty) {
      final dernierReleve = donnees.last;
      final mortalite = ((dernierReleve['mortalite'] ?? 0) as num).toInt();
      final temp = ((dernierReleve['temperature'] ?? 0) as num).toDouble();
      final hum = ((dernierReleve['humidite'] ?? 0) as num).toDouble();

      if (mortalite > 10) {
        add(
          titre: '🚨 Mortalité critique !',
          message: '$mortalite morts enregistrés aujourd\'hui',
          type: 'danger',
          action: 'voir_donnees',
        );
      } else if (mortalite > 5) {
        add(
          titre: '⚠️ Mortalité élevée',
          message: '$mortalite morts — surveiller le troupeau',
          type: 'warning',
        );
      }

      if (temp > 33) {
        add(
          titre: '🌡️ Température critique !',
          message: '${temp.toStringAsFixed(1)}°C — risque de stress thermique',
          type: 'danger',
          action: 'voir_meteo',
        );
      }

      if (hum > 75) {
        add(
          titre: '💧 Humidité trop élevée',
          message: '${hum.toStringAsFixed(0)}% — aérer les bâtiments',
          type: 'warning',
        );
      }
    }

    // Alertes stocks
    for (final s in stocks) {
      final qte = ((s['quantite'] ?? 0) as num).toDouble();
      final seuil = ((s['seuil_alerte'] ?? 0) as num).toDouble();
      if (qte <= seuil) {
        add(
          titre: '📦 Stock bas: ${s['produit']}',
          message: 'Quantité: $qte ${s['unite']} — sous le seuil d\'alerte',
          type: 'warning',
          action: 'voir_stocks',
        );
      }
    }

    // Rappels cycles
    for (final c in cycles) {
      final statut = c['statut'] ?? '';
      if (statut == 'actif' || statut == 'en_cours') {
        try {
          final debut = DateTime.parse(c['date_debut'] ?? '');
          final jours = DateTime.now().difference(debut).inDays;
          if (jours == 35) {
            add(
              titre: '📅 J+35 pour ${c['nom']}',
              message: 'Semaine de finition — préparer la vente',
              type: 'info',
            );
          } else if (jours == 42) {
            add(
              titre: '🐔 J+42 pour ${c['nom']}',
              message: 'Âge optimal de vente atteint !',
              type: 'success',
            );
          }
        } catch (_) {}
      }
    }
  }

  // ── WhatsApp ──
  static Future<bool> envoyerWhatsApp({
    required String telephone,
    required String message,
  }) async {
    try {
      // Nettoyer le numéro (enlever espaces, +, etc.)
      final tel = telephone.replaceAll(RegExp(r'[^\d]'), '');
      final telFormate = tel.startsWith('221') ? tel : '221$tel';

      // Utiliser l'API WhatsApp Business (CallMeBot - gratuit)
      final url = Uri.parse(
          'https://api.callmebot.com/whatsapp.php?phone=$telFormate&text=${Uri.encodeComponent(message)}&apikey=YOUR_API_KEY');

      final response = await http.get(url)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('WhatsApp error: $e');
      return false;
    }
  }

  // ── Générer message alerte WhatsApp ──
  static String genererMessageAlerte({
    required String type,
    required Map? cycle,
    required Map? donnee,
  }) {
    final now = DateTime.now();
    final date = '${now.day}/${now.month}/${now.year}';
    final heure = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final nom = SessionManager.nom.isNotEmpty ? SessionManager.nom : 'Éleveur';
    final cycleName = cycle?['nom'] ?? 'Cycle inconnu';

    switch (type) {
      case 'mortalite_critique':
        final morts = donnee?['mortalite'] ?? 0;
        return '''🚨 *ALERTE KEWERE AISSA SMART*
📅 $date à $heure

Bonjour $nom,

⚠️ *Mortalité critique détectée !*
🐔 Cycle: $cycleName
💀 Morts aujourd'hui: $morts
🔴 Action immédiate requise

Connectez-vous à votre application pour plus de détails.

_Kewere Aissa Smart - Ferme Intelligente_ 🐔''';

      case 'temperature':
        final temp = donnee?['temperature'] ?? 0;
        return '''🌡️ *ALERTE TEMPÉRATURE*
📅 $date à $heure

Bonjour $nom,

🔥 Température anormale détectée !
🐔 Cycle: $cycleName
🌡️ Température: ${temp}°C
⚠️ Seuil critique dépassé

Vérifiez immédiatement la ventilation.

_Kewere Aissa Smart_ 🐔''';

      case 'rapport_hebdo':
        return '''📊 *RAPPORT HEBDOMADAIRE*
📅 Semaine du $date

Bonjour $nom,

Votre rapport hebdomadaire est disponible sur Kewere Aissa Smart.

Connectez-vous pour consulter:
✅ Performance de vos cycles
📈 Graphiques et tendances
💡 Recommandations IA

_Kewere Aissa Smart - Ferme Intelligente_ 🐔''';

      default:
        return '''📱 *KEWERE AISSA SMART*
$date à $heure

Bonjour $nom,

Nouvelle notification disponible dans votre application.

_Kewere Aissa Smart_ 🐔''';
    }
  }
}