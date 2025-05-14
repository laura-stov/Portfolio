import { Emprestimo } from "./Emprestimo";

export interface Leitor{
    leitorId?: string;
    emprestimoId?: string,
    nome: string;
    sobrenome: string;
    telefone: string;
    email: string;
    cpf: string;
    emprestimo?: Emprestimo;
}