import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';

/// Ícone de carrinho com badge de quantidade — usado no cabeçalho de toda
/// tela da loja (Home da loja, listagem, detalhe do produto). Lê direto o
/// `CartCubit` singleton, então o número já vem certo em qualquer lugar
/// sem cada tela buscar sozinha.
class CartIconButton extends StatelessWidget {
  const CartIconButton({this.size = 38, this.iconSize = 19, super.key});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = context.select(
      (CartCubit cubit) => cubit.state.cart.itemCount,
    );
    return InkWell(
      onTap: () => context.push('/store/cart'),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: iconSize,
              color: colors.textPrimary,
            ),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.surface, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
