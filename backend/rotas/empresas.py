from flask import Blueprint, jsonify, request
import psycopg2

from database.empresas import EmpresasDatabase

empresas_blueprint = Blueprint("empresas", __name__)


@empresas_blueprint.route("/empresas", methods=["GET"])
def get_empresas():
    return jsonify(EmpresasDatabase().get_empresas()), 200


@empresas_blueprint.route("/empresas", methods=["POST"])
def criar_empresa():
    dados = request.get_json()

    if not dados or not dados.get("nome") or not dados.get("endereco"):
        return jsonify({"erro": "nome e endereco sao obrigatorios"}), 400

    try:
        resultado = EmpresasDatabase().criar_empresa(
            dados["nome"], dados["endereco"], dados.get("telefones", [])
        )
    except psycopg2.errors.UniqueViolation:
        return jsonify({"erro": f"Ja existe uma empresa chamada '{dados['nome']}'"}), 400

    return jsonify(resultado), 201
