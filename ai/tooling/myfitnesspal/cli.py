import argparse
import datetime
import sys

from .config import load_config
from .client import get_client


def parse_target_date(raw_date: str | None) -> datetime.date:
    if not raw_date:
        return datetime.date.today()
    try:
        return datetime.datetime.strptime(raw_date, "%Y-%m-%d").date()
    except ValueError:
        print("Error: Invalid date format. Use YYYY-MM-DD.")
        sys.exit(1)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="MyFitnessPal CLI enxuta, explícita e idempotente.",
        epilog=(
            "Fluxo recomendado:\n"
            "  1) search-food --query 'banana' --meal 'Almoço' --weight 120g\n"
            "  2) confirm-add --pick 1 --weight 120g --meal 'Almoço'\n"
            "Saída padrão por comando: screen / relevant / warnings / next.\n"
            "Comandos seguros e repetíveis: launch, view-diary, dump-ui, search-food, status, cancel-add, meals."
        ),
        formatter_class=argparse.RawTextHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("launch", help="Abrir o app e deixá-lo pronto no diário")

    diary_parser = subparsers.add_parser(
        "view-diary", help="Abrir o diário sem modificar entradas"
    )
    diary_parser.add_argument(
        "--date", type=str, help="Data alvo em YYYY-MM-DD (default: today)"
    )

    dump_parser = subparsers.add_parser(
        "dump-ui", help="Salvar o XML atual da UI para inspeção"
    )
    dump_parser.add_argument(
        "--output", type=str, help="Caminho do arquivo XML", default="/tmp/mfp_dump.xml"
    )

    meals_parser = subparsers.add_parser(
        "meals", help="Listar refeições detectadas na tela do diário"
    )
    meals_parser.add_argument(
        "--date", type=str, help="Data alvo em YYYY-MM-DD (abre o diário primeiro)"
    )

    subparsers.add_parser("status", help="Mostrar estado pendente atual")
    subparsers.add_parser("cancel-add", help="Apagar busca pendente sem adicionar nada")

    search_parser = subparsers.add_parser(
        "search-food", help="Buscar alimentos sem adicionar nada"
    )
    search_parser.add_argument(
        "--query", required=True, type=str, help="Texto da busca"
    )
    search_parser.add_argument(
        "--meal", type=str, required=True, help="Refeição/slot alvo"
    )
    search_parser.add_argument(
        "--weight", type=str, help="Peso opcional para carregar no estado pendente"
    )
    search_parser.add_argument(
        "--limit", type=int, default=5, help="Número máximo de opções exibidas"
    )
    search_parser.add_argument(
        "--tab",
        type=str,
        choices=["all", "meals", "recipes", "foods"],
        help="Aba específica",
        default="all",
    )

    confirm_parser = subparsers.add_parser(
        "confirm-add", help="Confirmar adição de uma busca pendente"
    )
    confirm_parser.add_argument(
        "--pick", type=int, default=1, help="Índice 1-based da opção da última busca"
    )
    confirm_parser.add_argument(
        "--weight",
        type=str,
        help="Peso para logar (opcional; se omitido, usa Quick Add +)",
    )
    confirm_parser.add_argument(
        "--meal", type=str, help="Sobrescrever refeição salva no estado pendente"
    )

    return parser


def main():
    load_config()
    parser = build_parser()
    args = parser.parse_args()
    client = get_client()

    if args.command == "launch":
        client.launch()
        return

    if args.command == "view-diary":
        client.view_diary(parse_target_date(args.date))
        return

    if args.command == "dump-ui":
        ok = client.dump_ui(args.output)
        if not ok:
            sys.exit(1)
        return

    if args.command == "meals":
        client.view_diary(parse_target_date(args.date))
        client.list_meals()
        return

    if args.command == "status":
        client.status()
        return

    if args.command == "cancel-add":
        client.cancel_add()
        return

    if args.command == "search-food":
        client.search_food(
            args.query,
            target_meal=args.meal,
            weight_str=args.weight,
            limit=args.limit,
            tab=args.tab,
        )
        return

    if args.command == "confirm-add":
        ok = client.confirm_add(
            pick=args.pick, weight_str=args.weight, target_meal=args.meal
        )
        if not ok:
            sys.exit(1)
        return


if __name__ == "__main__":
    main()
