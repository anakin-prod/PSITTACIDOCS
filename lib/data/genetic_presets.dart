import '../logic/genetics.dart';

/// Une mutation pré-remplie, proposée pour une espèce donnée dans le
/// calculateur génétique. Chaque liste est validée par une source fiable
/// avant d'être ajoutée ici — jamais de mode de transmission deviné.
class MutationPreset {
  final String name;
  final InheritanceMode mode;

  /// Précision affichée à côté du nom (facultative).
  final String? note;

  const MutationPreset(this.name, this.mode, {this.note});
}

/// Mutations pré-remplies, par espèce (clé : nom scientifique de
/// assets/data/species.json). Limité aux gènes indépendants les uns des
/// autres : le calculateur traite chaque mutation séparément, donc des
/// mutations qui se disputent un même gène (séries d'allèles) ne peuvent pas
/// y figurer ensemble sans fausser le résultat.
const Map<String, List<MutationPreset>> geneticPresets = {
  // Perruche ondulée (Melopsittacus undulatus) — validé le 29/09/2026.
  // Sources : fiches Wikipédia par mutation (citant Taylor & Warner,
  // « Genetics for Budgerigar Breeders » ; Rogers, « World of Budgerigars »)
  // et la synthèse « Budgerigar colour genetics » (citant Terry Martin,
  // « A Guide to Colour Mutations and Genetics in Parrots » ; Jim Hayward,
  // « The Manual of Colour Breeding »).
  'Melopsittacus undulatus': [
    MutationPreset('Bleu', InheritanceMode.autosomalRecessive),
    MutationPreset('Lutino / Albino (Ino)', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Cinnamon', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Opaline', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Slate', InheritanceMode.sexLinkedRecessive, note: 'rare'),
    MutationPreset('Pied hollandais (récessif)', InheritanceMode.autosomalRecessive),
    MutationPreset('Fallow allemand', InheritanceMode.autosomalRecessive),
    MutationPreset('Fallow anglais', InheritanceMode.autosomalRecessive),
    MutationPreset('Fallow écossais', InheritanceMode.autosomalRecessive, note: 'yeux prune'),
    MutationPreset('Fallow australien', InheritanceMode.autosomalRecessive),
    MutationPreset('Face noire (Blackface)', InheritanceMode.autosomalRecessive),
    MutationPreset('Gris', InheritanceMode.dominant),
    MutationPreset('Anthracite', InheritanceMode.incompleteDominant),
    MutationPreset('Clearbody dominant (Easley)', InheritanceMode.dominant),
    MutationPreset('Facteur sombre (Cobalt/Mauve, Vert foncé/Olive)', InheritanceMode.incompleteDominant),
    MutationPreset('Violet', InheritanceMode.incompleteDominant),
    MutationPreset('Spangle', InheritanceMode.incompleteDominant),
    MutationPreset('Pied dominant australien', InheritanceMode.incompleteDominant),
    MutationPreset('Pied continental (Clearflight)', InheritanceMode.incompleteDominant),
  ],

  // Calopsitte élégante (Nymphicus hollandicus) — validé le 29/09/2026.
  // Sources : fiches Wikipédia (« Cockatiel colour genetics », « Lutino
  // cockatiel », « White-faced cockatiel », « Pied cockatiel »), AFA
  // Watchbird (revue de la National Cockatiel Society) et
  // cockatielgenetics.com pour la confirmation du caractère indépendant de
  // la Face blanche.
  'Nymphicus hollandicus': [
    MutationPreset('Pied (panaché)', InheritanceMode.autosomalRecessive),
    MutationPreset('Cinnamon', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Perle (Opaline)', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Lutino', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Face blanche (Whiteface)', InheritanceMode.autosomalRecessive),
    MutationPreset('Argenté dominant', InheritanceMode.incompleteDominant),
    MutationPreset('Joues jaunes dominant', InheritanceMode.dominant, note: 'mutation récente'),
    MutationPreset('Joues jaunes lié au sexe', InheritanceMode.sexLinkedRecessive, note: 'mutation récente'),
  ],

  // Inséparable rosegorge (Agapornis roseicollis) — validé le 29/09/2026.
  // Source : Wikipédia, « Rosy-faced lovebird colour genetics ».
  // Le Bleu n'est présenté qu'en version simple (sans distinguer les variantes
  // Aqua et Turquoise, qui se disputent le même gène).
  'Agapornis roseicollis': [
    MutationPreset('Bleu', InheritanceMode.autosomalRecessive),
    MutationPreset('Lutino', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Opaline', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Pallid (Cinnamon australien)', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Facteur sombre', InheritanceMode.incompleteDominant),
    MutationPreset('Violet', InheritanceMode.incompleteDominant),
    MutationPreset('Face orange (Orangeface)', InheritanceMode.incompleteDominant),
    MutationPreset('Dilué bordé (Edged Dilute)', InheritanceMode.autosomalRecessive),
  ],

  // Perruche à collier (Psittacula krameri) — validé le 29/09/2026. Liste plus
  // courte : sources moins précises que pour les autres espèces au-delà de
  // ces trois mutations (Fallow, Violet et Gris mentionnés ailleurs mais sans
  // mode de transmission confirmé de façon fiable).
  // Sources : AFA Watchbird (revue de l'African Fanciers Association).
  'Psittacula krameri': [
    MutationPreset('Bleu', InheritanceMode.autosomalRecessive),
    MutationPreset('Lutino', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Cinnamon', InheritanceMode.sexLinkedRecessive),
  ],

  // Conure de Molina (Pyrrhura molinae) — validé le 29/09/2026.
  // Sources : exoticwings.ca (classification par mode de transmission),
  // recoupée avec des cas réels d'éleveurs sur parrotforums.com.
  'Pyrrhura molinae': [
    MutationPreset('Yellow-sided (flancs jaunes)', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Cinnamon', InheritanceMode.sexLinkedRecessive),
    MutationPreset('Turquoise', InheritanceMode.autosomalRecessive),
    MutationPreset('Dilute', InheritanceMode.autosomalRecessive),
    MutationPreset('Violet', InheritanceMode.incompleteDominant),
  ],
};
