import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 20;
  static const double xl  = 32;
  static const double full = 999;

  static BorderRadius circular(double r) => BorderRadius.circular(r);
  static BorderRadius get smAll  => BorderRadius.circular(sm);
  static BorderRadius get mdAll  => BorderRadius.circular(md);
  static BorderRadius get lgAll  => BorderRadius.circular(lg);
}
