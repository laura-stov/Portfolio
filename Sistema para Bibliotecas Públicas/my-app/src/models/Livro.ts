import internal from "stream"
import { Autor } from "./Autor"
import { Emprestimo } from "./Emprestimo";

export interface Livro {
    livroId?: string;
    emprestimoId?: string;
    titulo: string;
    genero: string;
    qtdExemplares: number;
    anoLancamento: number;
    criadoEm?: string;
    editora: string
    autorId: string;
    autor?: Autor; 
    emprestimo?: Emprestimo;
}