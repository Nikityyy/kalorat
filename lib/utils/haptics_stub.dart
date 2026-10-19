import 'package:flutter/services.dart';

void tick() => HapticFeedback.lightImpact();

void selection() => HapticFeedback.selectionClick();

void confirm() => HapticFeedback.mediumImpact();

void openTest(String labelsJson) {}
