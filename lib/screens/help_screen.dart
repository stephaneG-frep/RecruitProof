import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode d’emploi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bienvenue dans RecruitProof',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'L’application vous aide à préparer un dossier compréhensible '
                  'pour votre conseiller. Elle peut aussi consolider des exports '
                  'manuels venant de JobTime Proof et JobTracker.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            number: '1',
            title: 'Le principe en trois gestes',
            subtitle: 'Une méthode simple à répéter après chaque démarche.',
          ),
          const SizedBox(height: 12),
          const _Workflow(),
          const SizedBox(height: 26),
          const _SectionTitle(
            number: '2',
            title: 'Votre parcours pas à pas',
            subtitle: 'Découvrez le rôle de chaque rubrique.',
          ),
          const SizedBox(height: 12),
          const _GuideCard(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard : voir l’essentiel',
            color: Colors.blue,
            description:
                'Consultez l’état du dossier de preuves : rapports ajoutés, '
                'sources importées, temps déclaré et dernier dossier généré.',
            tips: [
              'Utilisez-le pour vérifier si le dossier du mois est solide.',
              'Touchez « Statistiques » pour obtenir une vue plus détaillée.',
            ],
          ),
          const _GuideCard(
            icon: Icons.note_add_outlined,
            title: 'Compléments : ajouter ce qui manque',
            color: Colors.indigo,
            description:
                'Appuyez sur « Nouveau complément » pour ajouter une précision, '
                'une action oubliée, une note pour le conseiller ou une preuve '
                'isolée non présente dans les rapports importés.',
            tips: [
              'Exemple : « Précision sur la relance de telle entreprise ».',
              'Utilisez « À vérifier » si une information doit être complétée.',
              'La durée déclarée reste optionnelle mais peut aider le rapport.',
            ],
          ),
          const _GuideCard(
            icon: Icons.attachment_outlined,
            title: 'Preuves : joindre vos documents',
            color: Colors.green,
            description:
                'Ajoutez manuellement une capture d’écran, une photo, un PDF '
                'ou un document. Un complément peut contenir plusieurs preuves.',
            tips: [
              'Ajoutez une preuve depuis le formulaire de complément pour la lier.',
              'Vérifiez que les informations sensibles peuvent être partagées.',
              'Une suppression demande toujours votre confirmation.',
            ],
          ),
          const _GuideCard(
            icon: Icons.timer_outlined,
            title: 'Temps : déclarer une estimation',
            color: Colors.deepPurple,
            description:
                'Choisissez un type de complément, estimez le temps passé par '
                'tranches de 10 minutes, ajoutez une note, puis enregistrez.',
            tips: [
              'RecruitProof ne surveille aucune autre application.',
              'L’estimation est volontaire et sert à compléter le dossier.',
            ],
          ),
          const _GuideCard(
            icon: Icons.description_outlined,
            title: 'Rapport : préparer le dossier final',
            color: Colors.orange,
            description:
                'Saisissez votre nom, choisissez une période, importez si besoin '
                'vos exports JobTime Proof ou JobTracker, puis exportez un PDF '
                'récapitulatif ou un ZIP contenant le PDF et les preuves.',
            tips: [
              'JobTime Proof sert au suivi quotidien du temps et des sessions.',
              'JobTracker sert au suivi des candidatures et statuts.',
              'RecruitProof sert de classeur final hebdomadaire ou mensuel.',
              'Relisez les compléments avant de générer le rapport.',
              'Le ZIP est pratique pour transmettre un dossier complet.',
              'Le fichier est créé localement sur votre appareil.',
            ],
          ),
          const _GuideCard(
            icon: Icons.upload_file_outlined,
            title: 'Imports : consolider sans espionner',
            color: Colors.teal,
            description:
                'Dans l’onglet Rapport, utilisez « Sources consolidées » pour '
                'ajouter plusieurs PDF générés par JobTime Proof ou '
                'JobTracker. Si vous avez plus tard un export JSON/CSV, il reste '
                'aussi accepté. RecruitProof ne va jamais chercher ces données tout seul.',
            tips: [
              'Les rapports PDF sont des preuves du dossier final.',
              'Vous pouvez en ajouter plusieurs pour une semaine ou un mois.',
              'Les PDF sont ajoutés au ZIP final dans le dossier preuves.',
              'Un nouvel import JSON/CSV remplace les anciennes données structurées de la même source.',
              'Vous pouvez retirer une source importée sans supprimer le fichier original.',
              'Les imports restent stockés localement dans RecruitProof.',
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            number: '3',
            title: 'Comprendre les statuts',
            subtitle:
                'Ils vous aident à contrôler la qualité de votre dossier.',
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  _StatusLine(
                    color: Colors.grey,
                    title: 'Brouillon',
                    description: 'Le complément est enregistré mais incomplet.',
                  ),
                  Divider(height: 26),
                  _StatusLine(
                    color: Colors.orange,
                    title: 'À vérifier',
                    description:
                        'Une information ou une preuve doit être contrôlée.',
                  ),
                  Divider(height: 26),
                  _StatusLine(
                    color: Colors.green,
                    title: 'Validé',
                    description:
                        'Le complément est prêt à apparaître dans votre dossier.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vos données vous appartiennent',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'RecruitProof n’espionne pas vos actions, ne crée '
                          'aucun compte et n’envoie pas vos données vers un '
                          'serveur. Vous choisissez chaque information et chaque '
                          'preuve ajoutée.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: Text(number),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Workflow extends StatelessWidget {
  const _Workflow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 650;
        const steps = [
          _WorkflowStep(
            icon: Icons.add_task,
            title: '1. Notez',
            text: 'Ajoutez un complément après votre démarche.',
          ),
          _WorkflowStep(
            icon: Icons.attach_file,
            title: '2. Prouvez',
            text: 'Ajoutez les documents que vous avez choisis.',
          ),
          _WorkflowStep(
            icon: Icons.folder_zip_outlined,
            title: '3. Exportez',
            text: 'Générez votre dossier pour la période voulue.',
          ),
        ];
        if (vertical) {
          return const Column(children: steps);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: steps[0]),
            const Padding(
              padding: EdgeInsets.only(top: 34),
              child: Icon(Icons.arrow_forward),
            ),
            Expanded(child: steps[1]),
            const Padding(
              padding: EdgeInsets.only(top: 34),
              child: Icon(Icons.arrow_forward),
            ),
            Expanded(child: steps[2]),
          ],
        );
      },
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.description,
    required this.tips,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String description;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .14),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}
