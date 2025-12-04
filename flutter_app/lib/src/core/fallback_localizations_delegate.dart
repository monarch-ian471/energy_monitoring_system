import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class FallbackMaterialLocalisationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final l = locale.languageCode == 'ny' ? const Locale('en') : locale;
    return await GlobalMaterialLocalizations.delegate.load(l);
  }

  @override
  bool shouldReload(FallbackMaterialLocalisationsDelegate old) => false;
}

class FallbackCupertinoLocalisationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    final l = locale.languageCode == 'ny' ? const Locale('en') : locale;
    return await GlobalCupertinoLocalizations.delegate.load(l);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}
