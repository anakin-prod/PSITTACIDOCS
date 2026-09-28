import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import '../widgets/google_logo.dart';
import 'account_screen.dart';

/// Connexion ou création de compte, par e-mail et mot de passe ou avec Google.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validEmail(String v) {
    final t = v.trim();
    return t.contains('@') && t.contains('.') && t.length >= 5;
  }

  /// Fin d'une tentative : affiche l'erreur, ou passe à l'écran du compte.
  void _finish(String? error) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null && Services.cloud.signedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      );
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text;
    final pass = _passCtrl.text;
    setState(() {
      _error = null;
      _info = null;
    });
    if (!_validEmail(email)) {
      setState(() => _error = 'Saisis une adresse e-mail valide.');
      return;
    }
    if (_register && pass.length < 8) {
      setState(() => _error = 'Choisis un mot de passe d’au moins 8 caractères.');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _error = 'Saisis ton mot de passe.');
      return;
    }
    setState(() => _busy = true);
    final result = _register
        ? await Services.cloud.registerWithEmail(email, pass)
        : await Services.cloud.signInWithEmail(email, pass);
    _finish(result);
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final result = await Services.cloud.signInWithGoogle();
    _finish(result);
  }

  Future<void> _forgot() async {
    final email = _emailCtrl.text;
    if (!_validEmail(email)) {
      setState(() {
        _error = 'Saisis d’abord ton adresse e-mail ci-dessus.';
        _info = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final result = await Services.cloud.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result;
      _info = result == null
          ? 'Si un compte existe avec cette adresse, un e-mail de réinitialisation vient d’être envoyé.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Créer un compte' : 'Se connecter')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: staggered([
          Text(
            _register ? 'Bienvenue' : 'Content de te revoir',
            style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.navy),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              PillChoice(
                label: const Text('Connexion'),
                selected: !_register,
                onSelected: _busy ? null : (_) => setState(() => _register = false),
              ),
              const SizedBox(width: 8),
              PillChoice(
                label: const Text('Nouveau compte'),
                selected: _register,
                onSelected: _busy ? null : (_) => setState(() => _register = true),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailCtrl,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Adresse e-mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            enabled: !_busy,
            obscureText: _obscure,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              helperText: _register ? '8 caractères minimum' : null,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (!_register)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _busy ? null : _forgot, child: const Text('Mot de passe oublié ?')),
            ),
          if (_error != null) InfoBanner(_error!, warning: true),
          if (_info != null) InfoBanner(_info!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(_register ? 'Créer mon compte' : 'Me connecter'),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou', style: TextStyle(fontSize: 12, color: AppColors.mute)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _busy ? null : _google,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: const GoogleLogo(size: 14),
                ),
                const SizedBox(width: 10),
                const Text('Continuer avec Google'),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
