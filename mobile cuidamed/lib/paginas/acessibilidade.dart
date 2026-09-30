import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/cabecalho.dart';
import '../componentes/cartao.dart';
import '../componentes/secao_ajuda.dart';
import '../estado/app_estado.dart';
import '../utilitarios/ajuda_conteudo.dart';
import '../utilitarios/tema.dart';
import 'edicao_perfil.dart';

/// Equivalente a paginas/Acessibilidade.jsx: guia sanfonado de todas as
/// telas (filtrado pelo tipo de usuário) + controle de tamanho da fonte.
class Acessibilidade extends StatefulWidget {
  const Acessibilidade({super.key});

  @override
  State<Acessibilidade> createState() => _AcessibilidadeState();
}

class _AcessibilidadeState extends State<Acessibilidade> {
  String? _chaveAberta;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final tipo = estado.usuario?.tipo ?? 'paciente';
    final secoes = guiaSecoes.where((s) => s.visivelPara(tipo)).toList();

    return AndaimeApp(
      appBar: const Cabecalho(kicker: 'Ajuda e acessibilidade', titulo: 'Acessibilidade'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Cartao(
            titulo: 'Tamanho da fonte',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ajusta o tamanho do texto em todo o aplicativo.', style: TextStyle(color: CorApp.textoSuave)),
                const SizedBox(height: 16),
                SeletorTamanhoFonte(estado: estado),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Cartao(
            titulo: 'Como usar cada tela',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Toque em uma tela para ver para que ela serve e como usá-la.',
                    style: TextStyle(color: CorApp.textoSuave)),
                const SizedBox(height: 12),
                for (final secao in secoes) _item(secao),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(SecaoAjuda secao) {
    final aberta = _chaveAberta == secao.chave;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: aberta ? CorApp.fundoDestaque : CorApp.fundoCard,
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        border: Border.all(color: aberta ? CorApp.azul : CorApp.borda, width: aberta ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: aberta,
            child: InkWell(
              borderRadius: BorderRadius.circular(RaioApp.pequeno),
              onTap: () => setState(() => _chaveAberta = aberta ? null : secao.chave),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        secao.titulo,
                        style: TextStyle(fontWeight: FontWeight.w800, color: aberta ? CorApp.azulTexto : CorApp.texto),
                      ),
                    ),
                    AnimatedRotation(
                      turns: aberta ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, color: CorApp.textoSuave),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: aberta
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: SecaoAjudaConteudo(secao: secao, mostrarTitulo: false),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
