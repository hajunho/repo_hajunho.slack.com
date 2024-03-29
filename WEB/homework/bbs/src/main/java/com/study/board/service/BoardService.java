package com.study.board.service;

import com.study.board.entity.Board;
import com.study.board.repository.BoardRepository;
import org.springframework.beans.factory.annotation.Autowired;
<<<<<<< .merge_file_A6JYe8
import org.springframework.stereotype.Service;

import java.util.List;
=======
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.List;
import java.util.UUID;
>>>>>>> .merge_file_uSqTbq

@Service
public class BoardService {
    @Autowired //이걸 넣으면 = new BoardRepository이걸 안 해줘도된다.
    private BoardRepository boardRepository;
    // 글작성
    public void write(Board board){
        boardRepository.save(board);
    }
    // 게시글 리스트 처리
<<<<<<< .merge_file_A6JYe8
    public List<Board> boardList(){
        return boardRepository.findAll();
=======
    public Page<Board> boardList(Pageable pageable) {

        return boardRepository.findAll(pageable);
    }
    public Page<Board> boardSearchList(String searchKeyword, Pageable pageable) {

        return boardRepository.findByTitleContaining(searchKeyword, pageable);
>>>>>>> .merge_file_uSqTbq
    }
    //특정 게시글 불러오기
    public Board boardView(Integer id){
        return boardRepository.findById(id).get();
    }
    //특정 게시글 삭제
    public void boardDelete(Integer id){boardRepository.deleteById(id);}
<<<<<<< .merge_file_A6JYe8


=======
>>>>>>> .merge_file_uSqTbq
}
