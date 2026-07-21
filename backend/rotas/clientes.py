from flask import Blueprint, jsonify, request
import psycopg2

from database.clientes import ClientesDatabase

clientes_blueprint = Blueprint("clientes", __name__)


@clientes_blueprint.route("/clientes", methods=["GET"])
def get_clientes():
    return jsonify(ClientesDatabase().get_clientes()), 200


@clientes_blueprint.route("/clientes", methods=["POST"])
def criar_cliente():
    dados = request.get_json()

    if not dados or not dados.get("cpf") or not dados.get("nome_completo"):
        return jsonify({"erro": "cpf e nome_completo sao obrigatorios"}), 400

    try:
        resultado = ClientesDatabase().criar_cliente(
            dados["cpf"], dados.get("rg"), dados["nome_completo"],
            dados.get("endereco"), dados.get("telefone"),
        )
    except psycopg2.errors.UniqueViolation:
        return jsonify({"erro": "Ja existe um cliente com esse CPF"}), 400

    return jsonify(resultado), 201
