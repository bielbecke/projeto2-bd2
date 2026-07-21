from flask import Blueprint, jsonify, request
import psycopg2

from database.servicos import ServicosDatabase

servicos_blueprint = Blueprint("servicos", __name__)


@servicos_blueprint.route("/servicos", methods=["GET"])
def get_servicos():
    return jsonify(ServicosDatabase().get_servicos()), 200


@servicos_blueprint.route("/servicos", methods=["POST"])
def criar_servico():
    dados = request.get_json()

    if not dados or not dados.get("nome_servico"):
        return jsonify({"erro": "nome_servico e obrigatorio"}), 400

    try:
        resultado = ServicosDatabase().criar_servico(
            nome_servico=dados["nome_servico"],
            tipo_servico=dados.get("tipo_servico"),
            especializacao=dados.get("especializacao"),  # None | "GUINDASTE" | "TRANSPORTE"
            tamanho_base=dados.get("tamanho_base"),
            altura=dados.get("altura"),
            bonus_aum=dados.get("bonus_aum", 0),
            limite_carga=dados.get("limite_carga"),
            faixas=dados.get("faixas", []),
        )
    except psycopg2.errors.UniqueViolation:
        return jsonify({"erro": f"Ja existe um servico chamado '{dados['nome_servico']}'"}), 400
    except psycopg2.Error as erro:
        # pega o trigger de disjuncao da hierarquia (item a): um servico nao
        # pode ser Guindaste e Transporte ao mesmo tempo
        return jsonify({"erro": str(erro).split("\n")[0]}), 400

    return jsonify(resultado), 201


# ---------------- oferece: empresa x cidade x servico -> preco/hora ----------------
@servicos_blueprint.route("/oferece", methods=["GET"])
def get_ofertas():
    id_empresa = request.args.get("id_empresa", type=int)
    nome_cidade = request.args.get("nome_cidade", type=str)
    estado = request.args.get("estado", type=str)

    resultado = ServicosDatabase().get_ofertas(id_empresa, nome_cidade, estado)
    return jsonify(resultado), 200


@servicos_blueprint.route("/oferece", methods=["POST"])
def criar_oferta():
    dados = request.get_json()
    obrigatorios = ["id_empresa", "nome_cidade", "estado", "nome_servico", "preco_hora"]

    if not dados or any(campo not in dados for campo in obrigatorios):
        return jsonify({"erro": f"campos obrigatorios: {', '.join(obrigatorios)}"}), 400

    try:
        resultado = ServicosDatabase().criar_oferta(
            dados["id_empresa"], dados["nome_cidade"], dados["estado"],
            dados["nome_servico"], dados["preco_hora"],
        )
    except psycopg2.Error as erro:
        return jsonify({"erro": str(erro).split("\n")[0]}), 400

    return jsonify(resultado), 201
