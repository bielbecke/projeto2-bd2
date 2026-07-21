from flask import Blueprint, jsonify, request

from database.cidades import CidadesDatabase

cidades_blueprint = Blueprint("cidade", __name__)


@cidades_blueprint.route("/cidades", methods=["GET"])
def get_cidades():
    return jsonify(CidadesDatabase().get_cidades()), 200


@cidades_blueprint.route("/cidades", methods=["POST"])
def criar_cidade():
    dados = request.get_json()

    if not dados or not dados.get("nome_cidade") or not dados.get("estado"):
        return jsonify({"erro": "nome_cidade e estado sao obrigatorios"}), 400

    resultado = CidadesDatabase().criar_cidade(dados["nome_cidade"], dados["estado"])
    return jsonify(resultado), 201
