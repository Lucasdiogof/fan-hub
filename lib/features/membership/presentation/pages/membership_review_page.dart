import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/membership_registration_validators.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/masks.dart';

/// Não conta como uma quarta etapa do stepper — é a tela que aparece depois
/// da Etapa 3, dentro do mesmo fluxo/cubit.
class MembershipReviewPage extends StatelessWidget {
  const MembershipReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final data = state.data;
    final colors = context.colors;
    final birthDate = parseDdMmYyyy(data.birthDate);

    return ListView(
      children: [
        Text(
          'REVISE SUA ASSOCIAÇÃO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _ReviewSection(
          title: 'PLANO',
          rows: [
            _ReviewRow('Plano', state.plan.name),
            if (state.plan.stadiumSector != null)
              _ReviewRow('Setor', state.plan.stadiumSector!),
            if (state.price.label.isNotEmpty)
              _ReviewRow('Opção', state.price.label),
          ],
        ),
        _ReviewSection(
          title: 'DADOS DO TITULAR',
          rows: [
            _ReviewRow('Nome', data.fullName),
            _ReviewRow('CPF', maskCpf(data.cpf)),
            if (data.passport.trim().isNotEmpty)
              _ReviewRow('Passaporte', data.passport),
            _ReviewRow('Nascimento', birthDate == null ? '-' : data.birthDate),
          ],
        ),
        _ReviewSection(
          title: 'CONTATO',
          rows: [
            _ReviewRow('E-mail', maskEmail(data.contactEmail)),
            _ReviewRow('Celular', maskPhone(data.phone)),
          ],
        ),
        _ReviewSection(
          title: 'ENDEREÇO',
          rows: [
            _ReviewRow('Endereço', '${data.street}, ${data.number}'),
            _ReviewRow('Bairro', data.neighborhood),
            _ReviewRow('Cidade/UF', '${data.city} - ${data.state}'),
          ],
        ),
        _ReviewSection(
          title: 'VALOR',
          rows: [
            _ReviewRow('Mensal', formatBrl(state.price.monthlyPrice)),
            _ReviewRow('Anual', formatBrl(state.price.annualPrice)),
          ],
        ),
        Text(
          'TERMOS DA ASSOCIAÇÃO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.textHint,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RegulationAcceptance(
          value: state.regulationAccepted,
          onChanged: cubit.setRegulationAccepted,
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.rows});

  final String title;
  final List<_ReviewRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textHint,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegulationAcceptance extends StatelessWidget {
  const _RegulationAcceptance({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            checked: value,
            label: 'Li e aceito o Regulamento do Sócio Esmeralda',
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: value ? colors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onChanged(!value),
                  child: Text(
                    'Li e aceito o Regulamento do Sócio Esmeralda',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context.push('/membership/regulation'),
                  child: Text(
                    'Ler regulamento completo →',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
