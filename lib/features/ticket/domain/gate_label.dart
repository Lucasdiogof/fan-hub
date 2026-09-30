/// Junta um rótulo (setor/torcida) com o portão — "Setor A · Portão 6".
///
/// Portão vazio é um estado REAL, não um erro: alguns clubes não publicam o
/// portão de cada setor (o Vila Nova, por exemplo, não informa portão nas
/// notícias oficiais de venda). Nesse caso o rótulo sai sozinho, nunca
/// "Setor A · " nem um portão inventado.
String withGate(String label, String gate) =>
    gate.trim().isEmpty ? label : '$label · $gate';
