import 'package:flutter/services.dart';
import 'package:goias_app/features/membership/data/regulation_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Corpo do texto do Regulamento do Sócio Esmeralda. Supabase é a fonte da
/// verdade pro CORPO do markdown; o asset local
/// (`RegulationCatalog.current.assetPath`) é o fallback offline/tabela
/// vazia. `id`/`version`/`effectiveAt` continuam vindo só do
/// [RegulationCatalog] no Dart — são o que fica gravado no aceite do sócio,
/// então não migram pra cá.
class MembershipRegulationRepository {
  MembershipRegulationRepository(this._client);

  final SupabaseClient _client;

  Future<String> loadCurrentMarkdown() async {
    try {
      final row = await _client
          .from('membership_regulation_versions')
          .select('content_markdown')
          .eq('id', RegulationCatalog.current.id)
          .maybeSingle();
      final markdown = row?['content_markdown'] as String?;
      if (markdown != null && markdown.trim().isNotEmpty) return markdown;
    } catch (_) {
      // cai pro asset local abaixo
    }
    return rootBundle.loadString(RegulationCatalog.current.assetPath);
  }
}
