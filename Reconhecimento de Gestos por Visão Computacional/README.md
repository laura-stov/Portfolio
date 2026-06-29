# Reconhecimento de Gestos por Visão Computacional

Este projeto tem como objetivo o reconhecimento e classificação de gestos através de técnicas de Visão Computacional. A solução processa imagens para identificar padrões específicos, permitindo a classificação automática baseada em um dataset pré-definido.

## Tech Stack
* **Linguagem:** Python
* **Bibliotecas Principais:** OpenCV (Processamento de imagem), Scikit-Learn (Validação de modelos)
* **Técnicas:** Pré-processamento de dados, Validação Cruzada (Cross-validation).

## Estrutura do Repositório
* `/Data`: Contém o dataset organizado por classes (ex: pasta `A/` contendo imagens de amostra para o gesto 'A').
* `cross_validation.py`: Script dedicado à avaliação da robustez do modelo, garantindo que a acurácia seja consistente em diferentes subconjuntos de dados.
* `.gitignore`: Configuração para ignorar arquivos desnecessários de sistema e pastas temporárias.

## Como funciona
1. **Coleta e Organização:** O projeto utiliza uma estrutura de diretórios onde cada pasta representa uma classe (gesto)[cite: 5].
2. **Processamento:** As imagens são carregadas e normalizadas.
3. **Treinamento e Validação:** Utiliza-se o script `cross_validation.py` para treinar e testar o modelo, evitando overfitting e garantindo métricas confiáveis[cite: 5].

## Como executar
1. Certifique-se de ter o Python instalado.
2. Instale as dependências: `pip install -r requirements.txt`
3. Execute a validação do modelo: `python cross_validation.py`

---
## Contato
Desenvolvido por **Laura Santos Oliveira**.
* [LinkedIn](https://www.linkedin.com/in/laura-oliveira-869024288) | [GitHub](https://github.com/laura-stov)
