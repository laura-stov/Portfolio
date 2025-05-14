import { useState } from "react";
import { Leitor } from "../../../models/Leitor";
import { useNavigate } from "react-router-dom";

function LeitorCadastro() {
    const [nome, setNome] = useState("");
    const [sobrenome, setSobrenome] = useState("");
    const [telefone, setTelefone] = useState("");
    const [email, setEmail] = useState("");
    const [cpf, setCPF] = useState("");
    const navigate = useNavigate();

    function enviarLeitor(e: any) {
        e.preventDefault();

        const leitor: Leitor = {
            nome: nome,
            sobrenome: sobrenome,
            telefone: telefone,
            email: email,
            cpf: cpf,
        };

        fetch("http://localhost:5274/biblioteca/leitor/cadastrar", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify(leitor),
        })
            .then((resposta) => resposta.json())
            .then(() => {
                console.log("Leitor cadastrado com sucesso");
                navigate("/pages/leitor/listar");
            })
            .catch((error) => {
                console.error("Erro ao cadastrar leitor:", error);
            });
    }

    // Função para garantir que o CPF tenha apenas números
    function handleCPFChange(e: any) {
        const cpfValue = e.target.value;
        const onlyNumbers = cpfValue.replace(/\D/g, ''); // Remove tudo que não for número
        setCPF(onlyNumbers);
    }

    return(
        <div id="cadastrar_leitor" className="container">
            <h1>Cadastrar Leitor</h1>
            <form onSubmit={enviarLeitor}>
                <div>
                    <label htmlFor="nome">Nome</label>
                    <input 
                        type="text" 
                        id="nome" 
                        name="nome" 
                        value={nome} 
                        required
                        onChange={(e: any) => setNome(e.target.value)}
                    />
                </div>

                <div>
                    <label htmlFor="sobrenome">Sobrenome</label>
                    <input 
                        type="text" 
                        name="sobrenome" 
                        id="sobrenome"
                        value={sobrenome}
                        required
                        onChange={(e: any) => setSobrenome(e.target.value)} 
                    />
                </div>

                <div>
                    <label htmlFor="telefone">Telefone</label>
                    <input 
                        type="text" 
                        name="telefone" 
                        id="telefone"
                        value={telefone}
                        required
                        onChange={(e: any) => setTelefone(e.target.value)} 
                    />
                </div>

                <div>
                    <label htmlFor="email">Email</label>
                    <input 
                        type="email" 
                        name="email" 
                        id="email"
                        value={email}
                        required
                        onChange={(e: any) => setEmail(e.target.value)} 
                    />
                </div>

                <div>
                    <label htmlFor="cpf">CPF</label>
                    <input 
                        type="text" 
                        name="cpf" 
                        id="cpf"
                        value={cpf}
                        required
                        onChange={handleCPFChange}
                        maxLength={11} 
                    />
                </div>

                <button type="submit">Cadastrar Leitor</button>
            </form>
        </div>
    );
}

export default LeitorCadastro;