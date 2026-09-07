import 'dart:math';

/// Avatares de foto (emojis) que o jogador pode escolher.
/// A foto é atribuída aleatoriamente até o jogador escolher uma.
const List<String> kAvatars = [
  '😀',
  '😎',
  '🤖',
  '👽',
  '🐱',
  '🐶',
  '🦊',
  '🐼',
  '🦄',
  '🐯',
  '🐸',
  '🐙',
  '👾',
  '🥷',
  '🦸',
  '🧙',
  '⚡',
  '🔥',
  '🌟',
  '🎮',
];

String randomAvatar() => kAvatars[Random().nextInt(kAvatars.length)];