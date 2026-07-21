#!/usr/bin/env python3
"""
GERADOR DE RELATÓRIO EM PDF - PROJETO 2 BD2
Sistema de Gestão de Pedidos de Logística
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak,
    KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from datetime import datetime

def criar_pdf():
    """Gera o relatório completo em PDF"""
    
    pdf_file = "RELATORIO_PROJETO_BD2.pdf"
    doc = SimpleDocTemplate(
        pdf_file,
        pagesize=A4,
        rightMargin=0.6*inch,
        leftMargin=0.6*inch,
        topMargin=0.6*inch,
        bottomMargin=0.6*inch
    )
    
    elements = []
    styles = getSampleStyleSheet()
    
    # Estilos customizados
    title_style = ParagraphStyle(
        'Title',
        parent=styles['Heading1'],
        fontSize=26,
        textColor=colors.HexColor('#1a4d7d'),
        spaceAfter=24,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=13,
        textColor=colors.HexColor('#1a4d7d'),
        spaceAfter=12,
        spaceBefore=12,
        fontName='Helvetica-Bold'
    )
    
    # CAPA
    elements.append(Spacer(1, 1*inch))
    elements.append(Paragraph("PROJETO 2 - BANCO DE DADOS II", title_style))
    elements.append(Spacer(1, 0.2*inch))
    elements.append(Paragraph(
        "Sistema de Gestão de Pedidos de Logística",
        ParagraphStyle('Subtitle', parent=styles['Normal'], fontSize=14,
                      alignment=TA_CENTER, textColor=colors.HexColor('#333333'),
                      fontName='Helvetica-Bold')
    ))
    elements.append(Spacer(1, 0.5*inch))
    elements.append(Paragraph(
        "<b>Autor:</b> bielbecke<br/>"
        f"<b>Data:</b> {datetime.now().strftime('%d de %B de %Y')}<br/>"
        "<b>Repositório:</b> github.com/bielbecke/projeto2-bd2",
        ParagraphStyle('Info', parent=styles['Normal'], fontSize=10,
                      alignment=TA_CENTER, textColor=colors.grey)
    ))
    elements.append(PageBreak())
    
    # ÍNDICE
    elements.append(Paragraph("ÍNDICE", heading_style))
    toc = [
        "1. Visão Geral do Projeto",
        "2. Arquitetura e Stack Tecnológico",
        "3. Estrutura do Banco de Dados",
        "4. Triggers e Regras de Negócio",
        "5. Backend Flask (API REST)",
        "6. Frontend React + Vite",
        "7. Fluxo de Dados (Exemplo Prático)",
        "8. Endpoints da API",
        "9. Como Executar",
        "10. Conclusão e Padrões Aplicados"
    ]
    for item in toc:
        elements.append(Paragraph(f"• {item}", styles['Normal']))
    elements.append(PageBreak())
    
    # 1. VISÃO GERAL
    elements.append(Paragraph("1. Visão Geral do Projeto", heading_style))
    elements.append(Paragraph(
        "<b>Objetivo Principal:</b> Desenvolver um sistema completo de gestão de pedidos de logística, "
        "integrando um banco de dados relacional (PostgreSQL) com uma API REST (Flask) e uma interface web moderna (React).",
        styles['BodyText']
    ))
    elements.append(Spacer(1, 0.15*inch))
    
    elements.append(Paragraph(
        "<b>Composição da Solução:</b>",
        styles['Normal']
    ))
    comp = [
        "✓ <b>Banco de Dados:</b> PostgreSQL 12+ com triggers para validação de regras de negócio",
        "✓ <b>Backend:</b> Python 3 + Flask para expor API REST",
        "✓ <b>Frontend:</b> React 18 + Vite para interface interativa",
        "✓ <b>Comunicação:</b> JSON via HTTP (REST)",
    ]
    for c in comp:
        elements.append(Paragraph(c, styles['Normal']))
    
    elements.append(Spacer(1, 0.15*inch))
    elements.append(Paragraph(
        "<b>Principais Funcionalidades:</b>",
        styles['Normal']
    ))
    funcs = [
        "• Gestão completa de entidades: Cidades, Empresas, Clientes, Funcionários, Serviços e Pedidos",
        "• Hierarquia de serviços com especialização em Guindastes e Transportes",
        "• Cálculo automático e complexo de preços baseado em múltiplos fatores",
        "• Validação de regras de negócio em tempo real via triggers SQL",
        "• Dashboard com 6 relatórios analíticos (histogramas e rankings top-5)",
        "• Atribuição dinâmica de funcionários a serviços",
    ]
    for f in funcs:
        elements.append(Paragraph(f, styles['Normal']))
    
    elements.append(PageBreak())
    
    # 2. ARQUITETURA
    elements.append(Paragraph("2. Arquitetura e Stack Tecnológico", heading_style))
    
    arch_data = [
        ['Camada', 'Tecnologia', 'Função'],
        ['Apresentação', 'React 18 + Vite + JavaScript ES6+', 'Interface web interativa e responsiva'],
        ['Negócio', 'Python 3 + Flask 3.0.3', 'API REST para operações CRUD e cálculos'],
        ['Persistência', 'PostgreSQL 12+', 'Armazenamento e validação via triggers'],
        ['Comunicação', 'REST API + JSON + CORS', 'Troca de dados entre cliente e servidor'],
    ]
    
    arch_table = Table(arch_data, colWidths=[1.2*inch, 2.0*inch, 2.3*inch])
    arch_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a4d7d')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#f9f9f9')),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('FONTSIZE', (0, 1), (-1, -1), 9),
    ]))
    elements.append(arch_table)
    
    elements.append(Spacer(1, 0.2*inch))
    elements.append(Paragraph(
        "<b>Dependências do Backend:</b>",
        styles['Normal']
    ))
    deps = [
        "• Flask 3.0.3 - Framework web minimalista e extensível",
        "• flask-cors 4.0.1 - Habilitação de CORS para requisições do frontend",
        "• psycopg2-binary 2.9.9 - Driver PostgreSQL para Python",
    ]
    for d in deps:
        elements.append(Paragraph(d, styles['Normal']))
    
    elements.append(PageBreak())
    
    # 3. BANCO DE DADOS
    elements.append(Paragraph("3. Estrutura do Banco de Dados", heading_style))
    
    elements.append(Paragraph(
        "O banco de dados é composto por 13 tabelas principais, todas normalizadas e com relacionamentos bem definidos:",
        styles['BodyText']
    ))
    elements.append(Spacer(1, 0.1*inch))
    
    db_data = [
        ['Tabela', 'Descrição', 'Chave Primária'],
        ['cidades', 'Localidades onde empresas prestam serviço', 'nome_cidade, estado'],
        ['empresas', 'Empresas prestadoras de logística', 'id_empresa'],
        ['clientes', 'Clientes que solicitam serviços', 'cod_cliente'],
        ['funcionarios', 'Funcionários das empresas', 'cpf_func'],
        ['servicos', 'Catálogo de serviços disponíveis', 'nome_servico'],
        ['guindastes', 'Especialização: Serviços tipo Guindaste', 'nome_servico (FK)'],
        ['transportes', 'Especialização: Serviços tipo Transporte', 'nome_servico (FK)'],
        ['oferece', 'Relação empresa-cidade-serviço-preço', 'id_empresa, cidade, estado, serviço'],
        ['pedidos', 'Solicitações dos clientes', 'codigo'],
        ['solicitam', 'Itens de serviço dentro de um pedido', 'id_solicitacao'],
        ['atendimento', 'Alocação de funcionários aos serviços', 'id_solicitacao, cpf_func'],
        ['vinculos', 'Vínculo empresa-funcionário', 'id_empresa, cpf_func'],
    ]
    
    db_table = Table(db_data, colWidths=[1.2*inch, 2.3*inch, 1.8*inch])
    db_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a4d7d')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#f9f9f9')),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
    ]))
    elements.append(db_table)
    
    elements.append(PageBreak())
    
    # 4. TRIGGERS E REGRAS
    elements.append(Paragraph("4. Triggers e Regras de Negócio", heading_style))
    
    elements.append(Paragraph(
        "Os triggers implementados no PostgreSQL garantem a integridade das regras de negócio, "
        "executados automaticamente na camada de banco de dados:",
        styles['BodyText']
    ))
    elements.append(Spacer(1, 0.1*inch))
    
    rules_data = [
        ['Regra', 'Descrição', 'Tipo'],
        ['(a) Hierarquia DISJUNTA',
         'Um serviço NÃO pode ser Guindaste E Transporte simultaneamente. Hierarquia é parcial (pode não ser nenhum).',
         'BEFORE INSERT'],
        ['(b) Cálculo de Preço por Item',
         'Preço = PrecoHora × tempo_duracao × (1 + percentual/100). Guindaste usa bonus fixo, Transporte usa faixa de carga.',
         'BEFORE INSERT/UPDATE'],
        ['(c) Preço Total do Pedido',
         'Preço_Total = SUM de todos os preços dos itens. Recalculado automaticamente a cada mudança.',
         'AFTER INSERT/UPDATE/DELETE'],
        ['(d) Validação de Cidades',
         'Cidade de DESTINO e PARTIDA do pedido devem estar na área de atuação da empresa.',
         'BEFORE INSERT/UPDATE'],
    ]
    
    rules_table = Table(rules_data, colWidths=[1.0*inch, 2.8*inch, 1.5*inch])
    rules_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a4d7d')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (0, -1), 'CENTER'),
        ('ALIGN', (1, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#f9f9f9')),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
    ]))
    elements.append(rules_table)
    
    elements.append(Spacer(1, 0.15*inch))
    elements.append(Paragraph(
        "<b>Características da Implementação:</b>",
        styles['Normal']
    ))
    chars = [
        "• Triggers BEFORE validam dados antes da inserção (regras a, d)",
        "• Trigger de cálculo executa BEFORE para estar pronto quando o AFTER dispara",
        "• Triggers AFTER somam totais e evitam inconsistências (regra c)",
        "• Mensagens de erro são capturadas e retornadas como JSON via API",
        "• Ordem de execução garantida: BEFORE (cálculo) → INSERT → AFTER (soma)",
    ]
    for char in chars:
        elements.append(Paragraph(char, styles['Normal']))
    
    elements.append(PageBreak())
    
    # 5. BACKEND FLASK
    elements.append(Paragraph("5. Backend Flask (API REST)", heading_style))
    
    elements.append(Paragraph(
        "O backend é organizado em 7 blueprints (módulos de rotas), cada um responsável por uma entidade do domínio:",
        styles['BodyText']
    ))
    elements.append(Spacer(1, 0.1*inch))
    
    backend_data = [
        ['Blueprint', 'Entidade', 'Endpoints Principais'],
        ['cidades_blueprint', 'Cidades', 'GET /cidades, POST /cidades'],
        ['clientes_blueprint', 'Clientes', 'GET /clientes, POST /clientes'],
        ['empresas_blueprint', 'Empresas', 'GET /empresas, POST /empresas'],
        ['funcionarios_blueprint', 'Funcionários', 'GET, POST /funcionarios; GET, POST, PATCH /vinculos'],
        ['servicos_blueprint', 'Serviços & Ofertas', 'GET, POST /servicos; GET, POST /oferece'],
        ['pedidos_blueprint', 'Pedidos', 'GET, POST /pedidos; PATCH resolver; POST atribuir funcionário'],
        ['dashboard_blueprint', 'Relatórios', 'GET /dashboard/* (6 endpoints analíticos)'],
    ]
    
    backend_table = Table(backend_data, colWidths=[1.3*inch, 1.3*inch, 2.7*inch])
    backend_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1a4d7d')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#f9f9f9')),
        ('GRID', (0, 0), (-1, -1), 1, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
    ]))
    elements.append(backend_table)
    
    elements.append(Spacer(1, 0.15*inch))
    elements.append(Paragraph(
        "<b>Padrão Arquitetural: MVC</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "• <b>Model (database/*.py):</b> Classes que encapsulam lógica de persistência e acesso a dados<br/>"
        "• <b>View (rotas/*.py):</b> Endpoints Flask que recebem requisições e retornam JSON<br/>"
        "• <b>Controller (main.py):</b> Registro de blueprints e orquestração da aplicação",
        styles['Normal']
    ))
    
    elements.append(PageBreak())
    
    # 6. FRONTEND REACT
    elements.append(Paragraph("6. Frontend React + Vite", heading_style))
    
    elements.append(Paragraph(
        "<b>Stack Tecnológico:</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "• React 18 - Biblioteca de componentes reativos<br/>"
        "• Vite - Build tool e dev server de alta performance<br/>"
        "• JavaScript ES6+ - Linguagem de programação<br/>"
        "• CSS3 - Estilização com design tokens",
        styles['Normal']
    ))
    
    elements.append(Spacer(1, 0.15*inch))
    elements.append(Paragraph(
        "<b>Estrutura de Arquivos:</b>",
        styles['Normal']
    ))
    structure = [
        "<b>src/api.js</b> - Camada HTTP com função fetch configurada",
        "<b>src/App.jsx</b> - Shell da aplicação e roteamento por abas",
        "<b>src/components/</b> - Componentes reutilizáveis (Sidebar, Cards, Gráficos, Toasts)",
        "<b>src/pages/</b> - 7 páginas principais (Dashboard, Pedidos, Empresas, Clientes, Serviços, Funcionários, Cidades)",
        "<b>src/styles.css</b> - Estilos globais com design tokens de cores e espaçamento",
    ]
    for s in structure:
        elements.append(Paragraph("• " + s, styles['Normal']))
    
    elements.append(Spacer(1, 0.15*inch))
    elements.append(Paragraph(
        "<b>Funcionalidades da Interface:</b>",
        styles['Normal']
    ))
    ui_features = [
        "✓ Listagem de todas as entidades com agregação de dados relacionados",
        "✓ Formulários de criação com validação de campos obrigatórios",
        "✓ Modais para atribuição de funcionários a serviços",
        "✓ Dashboard com 2 histogramas (quantidade e valor por cidade) + 4 rankings top-5",
        "✓ Gestão de vínculos empresa-funcionário (criar e encerrar)",
        "✓ Tratamento de erros com toasts (notificações visuais)",
        "✓ Filtros dinâmicos (ex: funcionários por empresa)",
    ]
    for f in ui_features:
        elements.append(Paragraph(f, styles['Normal']))
    
    elements.append(PageBreak())
    
    # 7. FLUXO DE DADOS
    elements.append(Paragraph("7. Fluxo de Dados (Exemplo Prático)", heading_style))
    
    elements.append(Paragraph(
        "<b>Cenário: Criação de um Pedido Completo com 2 Serviços</b>",
        styles['Normal']
    ))
    elements.append(Spacer(1, 0.1*inch))
    
    flow = [
        "1️⃣ <b>Usuário no Frontend:</b> Preenche formulário: empresa, cliente, cidades, itens de serviço com funcionários",
        "2️⃣ <b>Validação Frontend:</b> JavaScript verifica campos obrigatórios",
        "3️⃣ <b>Requisição HTTP:</b> POST para http://localhost:8000/pedidos com JSON no body",
        "4️⃣ <b>Backend recebe:</b> Flask desempacota JSON e chama PedidosDatabase.criar_pedido()",
        "5️⃣ <b>INSERT pedidos:</b> PostgreSQL insere pedido, trigger (d) valida se cidades existem na cobertura",
        "6️⃣ <b>INSERT solicitam:</b> Para cada item, insere serviço solicitado, trigger (c) calcula preço",
        "7️⃣ <b>INSERT atendimento:</b> Para cada funcionário de cada item, cria referência na tabela atendimento",
        "8️⃣ <b>AFTER trigger:</b> Recalcula preco_total em pedidos somando todos os itens",
        "9️⃣ <b>Resposta JSON:</b> Backend retorna {codigo, preco_total} com status 201 Created",
        "🔟 <b>Frontend exibe:</b> Toast de sucesso, atualiza lista de pedidos, limpa formulário",
    ]
    for step in flow:
        elements.append(Paragraph(step, styles['Normal']))
    
    elements.append(PageBreak())
    
    # 8. ENDPOINTS
    elements.append(Paragraph("8. Endpoints da API", heading_style))
    
    endpoints_text = """
    <b>🏙️ CIDADES</b><br/>
    GET /cidades - Listar todas as cidades cadastradas<br/>
    POST /cidades - Criar nova cidade (nome_cidade, estado)<br/>
    <br/>
    <b>👥 CLIENTES</b><br/>
    GET /clientes - Listar todos os clientes<br/>
    POST /clientes - Criar novo cliente<br/>
    <br/>
    <b>🏢 EMPRESAS</b><br/>
    GET /empresas - Listar todas as empresas com telefones agregados<br/>
    POST /empresas - Criar nova empresa (nome, endereco, telefones: [])<br/>
    <br/>
    <b>👨‍💼 FUNCIONÁRIOS</b><br/>
    GET /funcionarios - Listar todos ou filtrar por id_empresa<br/>
    GET /funcionarios?id_empresa=1 - Funcionários de uma empresa<br/>
    POST /funcionarios - Criar novo funcionário<br/>
    GET /funcionarios/vinculos - Listar todos os vínculos empresa-funcionário<br/>
    POST /funcionarios/vinculos - Criar novo vínculo<br/>
    PATCH /funcionarios/vinculos/{id_empresa}/{cpf_func}/encerrar - Encerrar vínculo<br/>
    <br/>
    <b>🔧 SERVIÇOS & OFERTAS</b><br/>
    GET /servicos - Listar todos os serviços (genéricos, Guindastes, Transportes)<br/>
    POST /servicos - Criar serviço com tipo (generico, guindaste, transporte)<br/>
    GET /oferece - Listar ofertas com filtros opcionais (id_empresa, nome_cidade, estado)<br/>
    POST /oferece - Criar oferta (id_empresa, nome_cidade, estado, nome_servico, preco_hora)<br/>
    <br/>
    <b>📦 PEDIDOS</b><br/>
    GET /pedidos - Listar todos com itens agrupados e funcionários<br/>
    POST /pedidos - Criar pedido com múltiplos itens e funcionários<br/>
    PATCH /pedidos/{codigo}/resolver - Marcar pedido como resolvido (aceito + data_resolucao)<br/>
    POST /pedidos/servicos/{id_solicitacao}/funcionarios - Atribuir funcionário a serviço<br/>
    <br/>
    <b>📊 DASHBOARD (6 Relatórios Analíticos)</b><br/>
    GET /dashboard/resumo - Totais: pedidos, faturado, pendentes, serviços<br/>
    GET /dashboard/qtd-por-cidade - Quantidade de serviços por cidade (TODAS)<br/>
    GET /dashboard/valor-por-cidade - Faturamento por cidade (TODAS)<br/>
    GET /dashboard/top-cidades-valor - Top 5 cidades por faturamento<br/>
    GET /dashboard/top-cidades-qtd - Top 5 cidades por quantidade de serviços<br/>
    GET /dashboard/top-empresas-qtd - Top 5 empresas por quantidade de serviços<br/>
    GET /dashboard/top-empresas-valor - Top 5 empresas por faturamento (aceitos + resolvidos)
    """
    
    elements.append(Paragraph(endpoints_text, styles['Normal']))
    elements.append(PageBreak())
    
    # 9. COMO EXECUTAR
    elements.append(Paragraph("9. Como Executar", heading_style))
    
    elements.append(Paragraph(
        "<b>Pré-requisitos:</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "• Python 3.9+<br/>"
        "• Node.js 16+ e npm<br/>"
        "• PostgreSQL 12+<br/>"
        "• Git",
        styles['Normal']
    ))
    
    elements.append(Spacer(1, 0.1*inch))
    elements.append(Paragraph(
        "<b>Passo 1: Clonar o Repositório</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "git clone https://github.com/bielbecke/projeto2-bd2.git<br/>"
        "cd projeto2-bd2",
        ParagraphStyle('Code', parent=styles['Normal'], fontName='Courier', fontSize=8,
                      backColor=colors.HexColor('#f0f0f0'), leftIndent=15, borderPadding=5)
    ))
    
    elements.append(Spacer(1, 0.1*inch))
    elements.append(Paragraph(
        "<b>Passo 2: Configurar PostgreSQL</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "1. Criar banco: createdb projeto_bd2<br/>"
        "2. Executar scripts SQL (em ordem):<br/>"
        "&nbsp;&nbsp;- backend/00_schema.sql (tabelas)<br/>"
        "&nbsp;&nbsp;- backend/01_dados.sql (dados iniciais)<br/>"
        "&nbsp;&nbsp;- backend/02_triggers.sql (triggers e funções)<br/>"
        "3. Configurar credenciais em backend/database/conector.py",
        styles['Normal']
    ))
    
    elements.append(Spacer(1, 0.1*inch))
    elements.append(Paragraph(
        "<b>Passo 3: Backend (Terminal 1)</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "cd backend<br/>"
        "python3 -m venv venv<br/>"
        "source venv/bin/activate<br/>"
        "pip install -r requirements.txt<br/>"
        "python main.py",
        ParagraphStyle('Code', parent=styles['Normal'], fontName='Courier', fontSize=8,
                      backColor=colors.HexColor('#f0f0f0'), leftIndent=15, borderPadding=5)
    ))
    
    elements.append(Spacer(1, 0.1*inch))
    elements.append(Paragraph(
        "<b>Passo 4: Frontend (Terminal 2)</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "cd frontend<br/>"
        "npm install<br/>"
        "npm run dev",
        ParagraphStyle('Code', parent=styles['Normal'], fontName='Courier', fontSize=8,
                      backColor=colors.HexColor('#f0f0f0'), leftIndent=15, borderPadding=5)
    ))
    
    elements.append(Spacer(1, 0.1*inch))
    elements.append(Paragraph(
        "<b>Passo 5: Acessar</b>",
        styles['Normal']
    ))
    elements.append(Paragraph(
        "Frontend: http://localhost:5173<br/>"
        "Backend: http://localhost:8000<br/>"
        "Status: http://localhost:8000/ → {\"status\": \"ok\"}",
        styles['Normal']
    ))
    
    elements.append(PageBreak())
    
    # 10. CONCLUSÃO
    elements.append(Paragraph("10. Conclusão e Padrões Aplicados", heading_style))
    
    conclusion = """
    Este projeto demonstra uma implementação <b>production-ready</b> de um sistema de gestão de pedidos de logística,
    integrando corretamente as três camadas de uma arquitetura moderna:<br/>
    <br/>
    <b>Camada de Dados (PostgreSQL):</b><br/>
    Banco relacional normalizado com 13 tabelas bem estruturadas e triggers complexos que implementam 
    regras de negócio sofisticadas (cálculo de preços, validações, integridade referencial). Todos os 
    cálculos e validações críticas ocorrem no banco, garantindo que não podem ser burlados pelo frontend ou API.<br/>
    <br/>
    <b>Camada de Negócio (Flask):</b><br/>
    API REST que expõe funcionalidades de forma segura através de 7 blueprints organizados. Traduz erros 
    de negócio em mensagens amigáveis ao usuário e orquestra a lógica transacional com precisão.<br/>
    <br/>
    <b>Camada de Apresentação (React):</b><br/>
    Interface moderna, responsiva e intuitiva para gestão de entidades e visualização de dados analíticos. 
    Mantém estado local, comunica com backend via HTTP e oferece feedback visual em tempo real.<br/>
    <br/>
    <b>Padrões Arquiteturais Aplicados:</b><br/>
    ✓ <b>MVC</b> - Separação clara entre Model (banco), View (frontend) e Controller (rotas)<br/>
    ✓ <b>REST API</b> - Endpoints semânticos com métodos HTTP apropriados<br/>
    ✓ <b>Repository Pattern</b> - Database classes encapsulam lógica de acesso a dados<br/>
    ✓ <b>Trigger-based Validation</b> - Regras críticas implementadas no banco<br/>
    ✓ <b>Component-based UI</b> - React com componentes reutilizáveis<br/>
    ✓ <b>Error Handling</b> - Exceções traduzidas em JSON com contexto útil<br/>
    ✓ <b>CORS</b> - Comunicação segura entre domínios diferentes<br/>
    <br/>
    O sistema está pronto para evolução: novos endpoints, relatórios e funcionalidades podem ser adicionados 
    mantendo a coesão arquitetural. As regras de negócio estão centralizadas no banco de dados, facilitando 
    manutenção e garantindo consistência em qualquer ponto de acesso aos dados.
    """
    
    elements.append(Paragraph(conclusion, styles['BodyText']))
    
    # RODAPÉ
    elements.append(Spacer(1, 0.3*inch))
    elements.append(Paragraph(
        f"Relatório gerado em {datetime.now().strftime('%d/%m/%Y às %H:%M')}<br/>"
        "Projeto 2 - Banco de Dados II | github.com/bielbecke/projeto2-bd2",
        ParagraphStyle('Footer', parent=styles['Normal'], fontSize=8,
                      alignment=TA_CENTER, textColor=colors.grey, borderPadding=10,
                      borderColor=colors.grey, borderWidth=1)
    ))
    
    # Construir PDF
    doc.build(elements)
    return pdf_file

if __name__ == "__main__":
    # Verificar se reportlab está disponível
    try:
        pdf = criar_pdf()
        print(f"\n✅ PDF gerado com sucesso: {pdf}")
        print(f"📄 Arquivo salvo no diretório atual")
    except ImportError:
        print("❌ Erro: reportlab não está instalado")
        print("📦 Instale com: pip install reportlab")
    except Exception as e:
        print(f"❌ Erro ao gerar PDF: {e}")
