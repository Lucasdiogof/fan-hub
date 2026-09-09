import 'package:goias_app/features/profile/domain/entities/legal_document.dart';

/// Textos legais do app — aplicativo independente de torcedor, sem vínculo
/// oficial com o clube. Responsável: Lucas Diogo França
/// (lucasdiogo1234@gmail.com). Atualize `lastUpdated` sempre que o texto
/// mudar de verdade. `clubName` vem de `ClubConfig.identity.displayName` —
/// nunca hardcoded, pra nunca falar "Goiás Esporte Clube" dentro do app de
/// outro clube.
class LegalDocumentsData {
  const LegalDocumentsData._();

  static LegalDocument termsOfUseFor(String clubName) => LegalDocument(
    title: 'TERMOS DE USO',
    lastUpdated: 'Última atualização: 25 de agosto de 2026',
    intro:
        'Estes Termos de Uso regulam a utilização deste aplicativo '
        'independente dedicado aos torcedores do $clubName, '
        'desenvolvido e mantido por Lucas Diogo França, contato pelo '
        'e-mail lucasdiogo1234@gmail.com.\n\n'
        'Ao criar uma conta ou utilizar o aplicativo, o usuário declara '
        'estar de acordo com estes Termos.',
    sections: [
      LegalSection(
        title: '1. Natureza do aplicativo',
        body:
            'Este aplicativo é um projeto independente, criado por torcedor, '
            'e não constitui aplicativo oficial, produto, serviço ou canal '
            'institucional do $clubName.\n\n'
            'O aplicativo não representa, não fala em nome e não mantém '
            'vínculo oficial com o $clubName, salvo se '
            'futuramente houver comunicação expressa em sentido '
            'contrário.\n\n'
            'Marcas, nomes, símbolos, escudos, imagens e demais elementos '
            'relacionados ao $clubName pertencem aos seus '
            'respectivos titulares.',
      ),
      LegalSection(
        title: '2. Finalidade',
        body:
            'O aplicativo possui finalidade informativa, recreativa e de '
            'interação entre torcedores, podendo disponibilizar '
            'funcionalidades como notícias, informações sobre jogos, '
            'minigames, quizzes, rankings, escalações históricas, '
            'votações e ferramentas relacionadas ao futebol e ao '
            '$clubName.\n\n'
            'As funcionalidades disponíveis podem ser alteradas, '
            'removidas ou ampliadas a qualquer momento.',
      ),
      LegalSection(
        title: '3. Cadastro e conta',
        body:
            'Para utilizar determinadas funcionalidades, poderá ser '
            'necessário criar uma conta. Atualmente poderão ser '
            'solicitados dados como nome, endereço de e-mail e senha.\n\n'
            'O usuário é responsável por fornecer informações verdadeiras '
            'e por manter suas credenciais de acesso protegidas. A conta '
            'é pessoal e não deve ser compartilhada com terceiros.',
      ),
      LegalSection(
        title: '4. Uso adequado',
        body:
            'O usuário compromete-se a utilizar o aplicativo de maneira '
            'lícita e adequada.\n\n'
            'Não é permitido tentar invadir, explorar vulnerabilidades, '
            'manipular resultados, interferir no funcionamento do '
            'serviço, utilizar sistemas automatizados de maneira '
            'abusiva, tentar acessar contas de terceiros ou praticar '
            'qualquer atividade que possa prejudicar o aplicativo ou '
            'seus usuários.\n\n'
            'Caso sejam identificadas atividades abusivas ou '
            'fraudulentas, a conta poderá ser suspensa ou encerrada.',
      ),
      LegalSection(
        title: '5. Minigames e rankings',
        body:
            'O aplicativo poderá disponibilizar jogos, desafios, rankings '
            'e sistemas de progresso.\n\n'
            'Pontuações, posições em ranking, estatísticas, resultados e '
            'regras poderão ser ajustados para corrigir erros, impedir '
            'fraudes, melhorar o equilíbrio das funcionalidades ou '
            'realizar mudanças no produto.\n\n'
            'O aplicativo não oferece prêmios financeiros, apostas ou '
            'qualquer tipo de jogo de azar.',
      ),
      LegalSection(
        title: '6. Escalação da Torcida e votações',
        body:
            'Funcionalidades como "Escalação da Torcida" representam '
            'apenas opiniões e votos dos próprios usuários.\n\n'
            'A escalação mais votada não representa uma escalação oficial '
            'do $clubName e não possui relação com decisões da '
            'comissão técnica ou do clube.',
      ),
      LegalSection(
        title: '7. Notícias e conteúdo externo',
        body:
            'O aplicativo poderá apresentar títulos, imagens, informações '
            'ou links de notícias provenientes do site oficial do '
            '$clubName e de outras fontes externas. Sempre que '
            'possível, a fonte original será identificada.\n\n'
            'Conteúdos pertencentes a terceiros permanecem sujeitos aos '
            'direitos de seus respectivos titulares. Ao acessar um link '
            'externo, o usuário também estará sujeito aos termos e '
            'políticas do site ou serviço acessado.',
      ),
      LegalSection(
        title: '8. Redes sociais e links externos',
        body:
            'O aplicativo poderá disponibilizar links para canais '
            'oficiais do $clubName em plataformas como '
            'Instagram, Facebook, YouTube, TikTok, X e outros serviços.\n\n'
            'Esses serviços são independentes do aplicativo e possuem '
            'seus próprios termos de uso e políticas de privacidade.',
      ),
      LegalSection(
        title: '9. Gratuidade',
        body:
            'O aplicativo é disponibilizado gratuitamente. Atualmente não '
            'são oferecidas assinaturas, compras dentro do aplicativo '
            'nem publicidade paga.\n\n'
            'Caso o modelo do aplicativo seja alterado futuramente, os '
            'Termos poderão ser atualizados antes da entrada em '
            'funcionamento dessas mudanças.',
      ),
      LegalSection(
        title: '10. Disponibilidade',
        body:
            'Não é possível garantir que o aplicativo permanecerá '
            'disponível de forma ininterrupta ou livre de falhas.\n\n'
            'Poderão ocorrer indisponibilidades decorrentes de '
            'manutenção, falhas técnicas, alterações em serviços de '
            'terceiros ou outras situações fora do controle do '
            'responsável pelo aplicativo.',
      ),
      LegalSection(
        title: '11. Informações de terceiros',
        body:
            'Algumas informações apresentadas podem depender de fontes '
            'externas, como resultados de jogos, escalações, notícias, '
            'datas, horários e estatísticas.\n\n'
            'Apesar dos esforços para manter as informações corretas e '
            'atualizadas, não é possível garantir absoluta precisão ou '
            'atualização em tempo real desses dados.',
      ),
      LegalSection(
        title: '12. Exclusão da conta',
        body:
            'O usuário poderá solicitar ou realizar a exclusão de sua '
            'conta por meio da funcionalidade disponibilizada no '
            'aplicativo.\n\n'
            'A exclusão poderá resultar na remoção ou anonimização de '
            'informações associadas à conta, ressalvados dados cuja '
            'conservação seja necessária para cumprimento de obrigação '
            'legal, prevenção a fraude, segurança ou exercício de '
            'direitos.',
      ),
      LegalSection(
        title: '13. Propriedade intelectual',
        body:
            'O código, estrutura, design, funcionalidades e conteúdos '
            'produzidos especificamente para este aplicativo pertencem '
            'aos seus respectivos criadores.\n\n'
            'Elementos pertencentes ao $clubName, veículos de '
            'comunicação, atletas, competições, plataformas ou terceiros '
            'permanecem de propriedade de seus respectivos titulares.',
      ),
      LegalSection(
        title: '14. Alterações destes Termos',
        body:
            'Estes Termos poderão ser atualizados para refletir novas '
            'funcionalidades, alterações legais ou mudanças no '
            'funcionamento do aplicativo.\n\n'
            'A versão mais recente deverá permanecer disponível dentro '
            'do próprio aplicativo.',
      ),
      LegalSection(
        title: '15. Contato',
        body:
            'Em caso de dúvidas, solicitações ou problemas relacionados '
            'ao aplicativo:\n\n'
            'Responsável: Lucas Diogo França\n'
            'E-mail: lucasdiogo1234@gmail.com',
      ),
    ],
  );

  static LegalDocument privacyPolicyFor(String clubName) => LegalDocument(
    title: 'POLÍTICA DE PRIVACIDADE',
    lastUpdated: 'Última atualização: 25 de agosto de 2026',
    intro:
        'Esta Política de Privacidade explica como os dados pessoais dos '
        'usuários são tratados neste aplicativo independente voltado aos '
        'torcedores do $clubName.\n\n'
        'O responsável pelo tratamento dos dados é Lucas Diogo França, '
        'que pode ser contatado pelo e-mail lucasdiogo1234@gmail.com.',
    sections: [
      LegalSection(
        title: '1. Dados coletados',
        body:
            'Para criação e utilização da conta, o aplicativo poderá '
            'coletar:\n\n'
            'Nome: utilizado para identificação do usuário dentro do '
            'aplicativo.\n\n'
            'E-mail: utilizado para identificação da conta, autenticação, '
            'recuperação de acesso e comunicações relacionadas ao '
            'serviço.\n\n'
            'Senha: utilizada para autenticação. A senha deve ser '
            'processada de forma segura pelo sistema responsável pela '
            'autenticação e não deve ser armazenada de forma legível.\n\n'
            'Além disso, podem ser gerados dados relacionados à '
            'utilização do aplicativo, como progresso nos minigames, '
            'respostas, pontuações, posição em rankings, escalações '
            'enviadas, votos e interações com funcionalidades.',
      ),
      LegalSection(
        title: '2. Dados técnicos',
        body:
            'O aplicativo poderá processar informações técnicas '
            'necessárias para funcionamento, segurança e diagnóstico, '
            'como identificadores técnicos, registros de erros, versão '
            'do aplicativo, sistema operacional, data e horário de '
            'acessos e registros de funcionamento.\n\n'
            'Essas informações poderão ser utilizadas para identificar '
            'falhas, melhorar desempenho, impedir abuso e manter a '
            'segurança do serviço.',
      ),
      LegalSection(
        title: '3. Finalidades do tratamento',
        body:
            'Os dados poderão ser utilizados para criar e administrar '
            'contas, autenticar usuários, salvar progresso, manter '
            'rankings, registrar votações e escalações, recuperar '
            'acesso, proteger o aplicativo contra abuso e fraude, '
            'corrigir erros e melhorar funcionalidades.\n\n'
            'Os dados não serão utilizados para venda de informações '
            'pessoais ou criação de publicidade direcionada.',
      ),
      LegalSection(
        title: '4. CPF e telefone',
        body:
            'Atualmente, esta Política considera o cadastro baseado em '
            'nome, e-mail e senha.\n\n'
            'Caso futuramente o aplicativo passe a solicitar telefone ou '
            'CPF, a finalidade da coleta deverá ser definida e esta '
            'Política deverá ser atualizada antes ou no momento em que '
            'essa coleta for disponibilizada.\n\n'
            'Nenhum dado pessoal deve ser solicitado sem uma finalidade '
            'legítima e claramente informada ao usuário.',
      ),
      LegalSection(
        title: '5. Base legal',
        body:
            'O tratamento de dados pessoais será realizado de acordo com '
            'a legislação brasileira aplicável, especialmente a Lei '
            'Geral de Proteção de Dados Pessoais — LGPD (Lei nº '
            '13.709/2018).\n\n'
            'Dependendo da operação, o tratamento poderá ocorrer para '
            'execução do serviço solicitado pelo usuário, cumprimento de '
            'obrigação legal, exercício legítimo de direitos, proteção '
            'contra fraude e segurança ou mediante consentimento, quando '
            'necessário.',
      ),
      LegalSection(
        title: '6. Compartilhamento de dados',
        body:
            'Os dados poderão ser processados por fornecedores '
            'necessários ao funcionamento técnico do aplicativo, como '
            'serviços de hospedagem, banco de dados, autenticação, '
            'armazenamento, monitoramento e infraestrutura.\n\n'
            'Esses fornecedores devem receber apenas os dados necessários '
            'para execução de seus serviços.\n\n'
            'Os dados pessoais dos usuários não são vendidos a '
            'anunciantes ou terceiros.',
      ),
      LegalSection(
        title: '7. Conteúdo público',
        body:
            'Caso determinada funcionalidade exiba publicamente nome, '
            'pontuação, posição em ranking ou outra informação vinculada '
            'ao perfil, somente os dados necessários para aquela '
            'funcionalidade deverão ser apresentados.\n\n'
            'Informações como e-mail e credenciais de acesso não devem '
            'ser exibidas publicamente.',
      ),
      LegalSection(
        title: '8. Notícias e serviços externos',
        body:
            'O aplicativo poderá apresentar notícias e links provenientes '
            'de sites externos, inclusive do site oficial do '
            '$clubName.\n\n'
            'Ao abrir um conteúdo em um serviço externo, o tratamento de '
            'dados realizado naquele ambiente passa a ser regido também '
            'pela política de privacidade do serviço acessado.\n\n'
            'O mesmo se aplica aos links para Instagram, YouTube, TikTok, '
            'Facebook, X e outras plataformas.',
      ),
      LegalSection(
        title: '9. Armazenamento e segurança',
        body:
            'Serão adotadas medidas técnicas e organizacionais razoáveis '
            'para proteger os dados contra acesso não autorizado, perda, '
            'alteração, divulgação ou utilização indevida.\n\n'
            'Nenhum sistema conectado à internet pode garantir segurança '
            'absoluta, mas serão adotadas práticas compatíveis com a '
            'natureza do serviço e dos dados tratados.',
      ),
      LegalSection(
        title: '10. Retenção',
        body:
            'Os dados serão mantidos enquanto forem necessários para '
            'manter a conta e disponibilizar as funcionalidades do '
            'aplicativo.\n\n'
            'Quando a conta for excluída, os dados pessoais associados '
            'deverão ser eliminados ou anonimizados dentro de prazo '
            'razoável, salvo quando sua conservação for necessária para '
            'cumprimento de obrigação legal, prevenção a fraude, '
            'segurança ou exercício de direitos.',
      ),
      LegalSection(
        title: '11. Exclusão da conta',
        body:
            'O aplicativo disponibilizará uma funcionalidade para que o '
            'usuário possa excluir sua própria conta.\n\n'
            'Antes da confirmação, o usuário deverá ser informado de que '
            'a exclusão pode ser irreversível e poderá apagar '
            'informações como progresso, pontuações, preferências, '
            'votos, escalações e demais dados associados à conta.\n\n'
            'Quando tecnicamente ou legalmente necessário, determinados '
            'registros poderão ser mantidos de maneira limitada pelo '
            'período necessário.',
      ),
      LegalSection(
        title: '12. Direitos do usuário',
        body:
            'Nos termos da LGPD, o usuário poderá solicitar informações '
            'relacionadas ao tratamento de seus dados, correção de dados '
            'incorretos, eliminação ou anonimização quando aplicável, '
            'informações sobre compartilhamento, revogação de '
            'consentimento quando esta for a base utilizada e demais '
            'direitos previstos pela legislação.\n\n'
            'Solicitações podem ser encaminhadas para '
            'lucasdiogo1234@gmail.com.',
      ),
      LegalSection(
        title: '13. Crianças e adolescentes',
        body:
            'O aplicativo não tem como finalidade específica a coleta de '
            'dados de crianças.\n\n'
            'Caso sejam disponibilizadas funcionalidades destinadas '
            'especificamente a menores de idade, poderão ser '
            'implementadas medidas adicionais de proteção e '
            'consentimento conforme exigido pela legislação.',
      ),
      LegalSection(
        title: '14. Publicidade e comercialização de dados',
        body:
            'Atualmente o aplicativo: não possui publicidade; não possui '
            'assinaturas; não possui compras dentro do aplicativo; não '
            'vende dados pessoais dos usuários.\n\n'
            'Caso essas condições sejam alteradas futuramente, esta '
            'Política deverá ser atualizada.',
      ),
      LegalSection(
        title: '15. Alterações da Política',
        body:
            'Esta Política poderá ser atualizada em razão de novas '
            'funcionalidades, alterações técnicas ou mudanças legais.\n\n'
            'A versão vigente deverá permanecer disponível dentro do '
            'aplicativo.',
      ),
      LegalSection(
        title: '16. Contato',
        body:
            'Para dúvidas relacionadas à privacidade ou aos dados '
            'pessoais:\n\n'
            'Responsável: Lucas Diogo França\n'
            'E-mail: lucasdiogo1234@gmail.com',
      ),
    ],
  );
}
