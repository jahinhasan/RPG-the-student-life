class RoleAbility {
  final String playstyle;
  final String ability;
  final String description;

  const RoleAbility({
    required this.playstyle,
    required this.ability,
    required this.description,
  });
}

class RoleAbilitySystem {
  static RoleAbility forPlaystyle(String playstyleRaw) {
    final playstyle = playstyleRaw.toLowerCase();

    switch (playstyle) {
      case 'fighter':
        return const RoleAbility(
          playstyle: 'Fighter',
          ability: '+10% attack',
          description: 'Battle damage bonus in arena mode.',
        );
      case 'explorer':
        return const RoleAbility(
          playstyle: 'Explorer',
          ability: 'Faster map progress',
          description: 'Higher world progression gain per quest.',
        );
      case 'tactical':
        return const RoleAbility(
          playstyle: 'Tactical',
          ability: 'Better accuracy',
          description: 'Improved answer precision and strategic bonus.',
        );
      case 'scholar':
      default:
        return const RoleAbility(
          playstyle: 'Scholar',
          ability: '+20% quiz XP',
          description: 'Additional XP for quiz performance.',
        );
    }
  }
}
