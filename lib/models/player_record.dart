/// Registro de um jogador local no placar/ranking.
class PlayerRecord {
  final String name;
  final String avatar;
  final bool isSelf;
  final int wins;
  final int losses;
  final int ties;
  final int diamonds;

  const PlayerRecord({
    required this.name,
    required this.avatar,
    this.isSelf = false,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.diamonds = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar': avatar,
        'isSelf': isSelf,
        'wins': wins,
        'losses': losses,
        'ties': ties,
        'diamonds': diamonds,
      };

  factory PlayerRecord.fromJson(Map<String, dynamic> json) => PlayerRecord(
        name: json['name'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        isSelf: json['isSelf'] as bool? ?? false,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        ties: json['ties'] as int? ?? 0,
        diamonds: json['diamonds'] as int? ?? 0,
      );
}