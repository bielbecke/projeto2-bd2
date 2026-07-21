from flask import Blueprint, jsonify, request
import psycopg2

from database.funcionarios import FuncionariosDatabase

funcionarios_blueprint = Blueprint("funcionarios", __name__)


@funcionarios_blueprint.route("/funcionarios", methods=["GET"])
def get_funcionarios():
    id_empresa = request.args.get("id_empresa", type=int)
    return jsonify(FuncionariosDatabase().get_funcionarios(id_empresa)), 200


@funcionarios_blueprint.route("/funcionarios", methods=["POST"])
def criar_funcionario():
    dados = request.get_json()

    if not dados or not dados.get("cpf_func") or not dados.get("nome_completo_func"):
        return jsonify({"erro": "cpf_func e nome_completo_func sao obrigatorios"}), 400

    try:
        resultado = FuncionariosDatabase().criar_funcionario(
            dados["cpf_func"], dados.get("rg_func"), dados.get("endereco_func"),
            dados["nome_completo_func"], dados.get("telefone_contato"),
            dados.get("salario"), dados.get("tipo_func"),
        )
    except psycopg2.errors.UniqueViolation:
        return jsonify({"erro": "Ja existe um funcionario com esse CPF"}), 400

    return jsonify(resultado), 201


# ---------------- vinculos: funcionario x empresa (N:N com periodo) ----------------
@funcionarios_blueprint.route("/funcionarios/vinculos", methods=["GET"])
def get_vinculos():
    return jsonify(FuncionariosDatabase().get_vinculos()), 200


@funcionarios_blueprint.route("/funcionarios/vinculos", methods=["POST"])
def criar_vinculo():
    dados = request.get_json()
    obrigatorios = ["id_empresa", "cpf_func", "data_inicio"]

    if not dados or any(campo not in dados for campo in obrigatorios):
        return jsonify({"erro": f"campos obrigatorios: {', '.join(obrigatorios)}"}), 400

    try:
        resultado = FuncionariosDatabase().criar_vinculo(
            dados["id_empresa"], dados["cpf_func"], dados["data_inicio"], dados.get("data_fim")
        )
    except psycopg2.Error as erro:
        return jsonify({"erro": str(erro).split("\n")[0]}), 400

    return jsonify(resultado), 201


@funcionarios_blueprint.route("/funcionarios/vinculos/<int:id_empresa>/<cpf_func>/encerrar", methods=["PATCH"])
def encerrar_vinculo(id_empresa, cpf_func):
    resultado = FuncionariosDatabase().encerrar_vinculo(id_empresa, cpf_func)

    if resultado is None:
        return jsonify({"erro": "Nenhum vinculo ativo encontrado"}), 404

    return jsonify({"ok": True}), 200
