from flask import Blueprint, jsonify, request

from database.pedidos import PedidosDatabase, PedidoInvalido

pedidos_blueprint = Blueprint("pedidos", __name__)


@pedidos_blueprint.route("/pedidos", methods=["GET"])
def get_pedidos():
    return jsonify(PedidosDatabase().get_pedidos()), 200


@pedidos_blueprint.route("/pedidos", methods=["POST"])
def criar_pedido():
    dados = request.get_json()
    obrigatorios = ["id_empresa", "cod_cliente", "cidade_dest", "estado_dest",
                     "cidade_part", "estado_part", "itens"]

    if not dados or any(campo not in dados for campo in obrigatorios):
        return jsonify({"erro": f"campos obrigatorios: {', '.join(obrigatorios)}"}), 400

    try:
        resultado = PedidosDatabase().criar_pedido(
            id_empresa=dados["id_empresa"],
            cod_cliente=dados["cod_cliente"],
            cidade_dest=dados["cidade_dest"], estado_dest=dados["estado_dest"],
            endereco_dest=dados.get("endereco_dest"),
            cidade_part=dados["cidade_part"], estado_part=dados["estado_part"],
            endereco_part=dados.get("endereco_part"),
            aceite=dados.get("aceite", False),
            itens=dados["itens"],
        )
    except PedidoInvalido as erro:
        return jsonify({"erro": str(erro)}), 400

    return jsonify(resultado), 201


@pedidos_blueprint.route("/pedidos/<int:codigo>/resolver", methods=["PATCH"])
def resolver_pedido(codigo):
    encontrado = PedidosDatabase().resolver_pedido(codigo)

    if not encontrado:
        return jsonify({"erro": "Pedido nao encontrado"}), 404

    return jsonify({"ok": True}), 200


@pedidos_blueprint.route("/pedidos/servicos/<int:id_solicitacao>/funcionarios", methods=["POST"])
def atribuir_funcionario(id_solicitacao):
    dados = request.get_json()

    if not dados or not dados.get("cpf_func"):
        return jsonify({"erro": "cpf_func e obrigatorio"}), 400

    try:
        resultado = PedidosDatabase().atribuir_funcionario(id_solicitacao, dados["cpf_func"])
    except PedidoInvalido as erro:
        return jsonify({"erro": str(erro)}), 400

    return jsonify(resultado), 201
