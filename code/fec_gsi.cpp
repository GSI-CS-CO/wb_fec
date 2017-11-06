#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <vector>
#include <iostream>
#include <cmath>
#include <iomanip>
#include <random>
#include <time.h>
#include <iterator>
#include <valarray>

void print_vector_vector( std::vector<std::vector<uint8_t >> vec, int pkt) {

        std::vector<uint8_t> tmp;
        for (size_t j = 0; j < vec.size(); j++) {
                tmp = vec[j];

                for (size_t i = 0; i < tmp.size(); i++)
                        std::cout << std::hex << int(vec[j][i]);
                if (pkt) {
                        std::cout << " || ";

                } else
                        std::cout << std::endl;
        }

        if(pkt)
                std::cout << std::endl;
}

int main(int argc, char * argv[]) {

        std::vector<uint8_t> distro_d1;
        std::vector<std::vector<uint8_t>> distro_d2;
        std::vector<uint8_t> pkt;
        std::vector<std::vector<uint8_t>> enc_pkt;
        std::vector<std::vector<uint8_t>> dec_pkt;
        srand (time(NULL));

        pkt = { 0xff, 0xe2, 0xd5, 0xbb, 0xf6, 0x2d,
                0x5b, 0xb7, 0x9e, 0xac, 0xb8, 0x71};

        distro_d1 = {0, 1, 2, 3};
        distro_d2 = {{2, 3}, {3, 0}, {0, 1}, {1, 2}};

        uint32_t num_block;
        uint32_t len_block;
        uint32_t len_block_mod;
        uint32_t len_enc_block = 6;

        std::vector<std::vector<uint8_t>> cw;

        if (argc < 2) {
                std::cerr << "Usage: " << argv[0] << " Number of blocks" << argv[1] <<std::endl;
                return 1;
        }

        num_block = atoi(argv[1]);
        len_block_mod = pkt.size() / num_block;

        if (len_block_mod == 0) {
                len_block = pkt.size() / num_block;
        } else {
                len_block = std::floor(pkt.size() / num_block);
        }

        std::cout << "Pkt size in words (8 bits): " << pkt.size() << " Num of blocks: " << num_block << " len block: " << len_block  << std::endl;

        std::vector<uint8_t> tmp;

        for (int j = 0; j < num_block; j++) {
                tmp = {};
                for (int i = 0; i < len_block; i++)
                        tmp.push_back(pkt[(j * 3) + i]);
                cw.push_back(tmp);
        }

        print_vector_vector(cw, 0);

        std::cout << "Encoding ---" << std::endl;

        //encoder
        uint32_t idx = 0;
        uint32_t idx_0 = 0;
        uint32_t idx_1 = 0;
        std::vector<uint8_t> tmp_0;
        std::vector<uint8_t> tmp_1;
        std::vector<uint8_t> tmp_xor;
        for (size_t j = 0; j < cw.size(); j++) {

                idx_0 = distro_d2[j][0];
                idx_1 = distro_d2[j][1];
                tmp_0 = cw[idx_0];
                tmp_1 = cw[idx_1];

                tmp_xor = {};

                for (size_t i = 0; i < tmp_0.size(); i++)
                        tmp_xor.push_back(tmp_0[i] ^ tmp_1[i]);

                idx = distro_d1[j];

                for (size_t i = 0; i < cw[idx].size(); i++)
                        tmp_xor.push_back(cw[idx][i]);

                tmp_xor.push_back(j);
                enc_pkt.push_back(tmp_xor);
        }

        print_vector_vector(enc_pkt, 1);

        //channel - erasure packet
        int max = 3;
        int num_pkt_lost = rand() % max;
        std::cout << "Packet Lost in the channel: " << num_pkt_lost << std::endl;

        for (int i = 0; i < num_pkt_lost; i++) {
                int pkt_lost = rand() % max;
                enc_pkt.erase(enc_pkt.begin() + pkt_lost);
                std::cout << "Packet " << pkt_lost << " is gone" << std::endl;
        }

        //decoder
        print_vector_vector(enc_pkt, 1);

        std::vector<uint8_t> codeword;
        std::vector<uint8_t> tmp_vec;
        std::vector<uint8_t> deco_pkt(12, 0);
        uint8_t rcv_pkt_idx = 0;
        uint8_t rcv_pkt_cnt = 0;
        std::vector<std::vector<uint8_t>> buffer(num_block, std::vector<uint8_t>(len_block,0));

        if (enc_pkt.size() >= 2) {
                for (int i = 0; i < enc_pkt.size(); i++) {
                        codeword = enc_pkt[i];
                        idx = codeword.back();
                        codeword.pop_back();

                        std::cout << "dimension 1 idx " << idx << std::endl;
                        for (int j = 0; j < len_block; j++) {
                                uint8_t tmp = codeword.at(len_block + j);
                                deco_pkt[(len_block * idx) + j] = tmp;
                        }
                        codeword.pop_back();

                        for (auto n:deco_pkt)
                            std::cout << std::hex << int(n) << " ";
                        std::cout << std::endl;

                        std::cout << "dimension 2 idx " << idx << std::endl;
                        tmp_vec = {};

                        for (int j = 0; j < len_block; j++)
                                tmp_vec.push_back(codeword.at(j));

                        buffer[idx] = tmp_vec;

                        print_vector_vector(buffer, 1);

                        std::cout << "-----------" << std::endl;

                        rcv_pkt_idx = rcv_pkt_idx ^ idx << (2 * rcv_pkt_cnt);
                        rcv_pkt_cnt += 1;

                        std::cout << "pkt_idx " << int(rcv_pkt_idx) << " rcv_pkt_cnt " << int(rcv_pkt_cnt) << std::endl;

                        if (rcv_pkt_cnt >= 2) {
                                if (rcv_pkt_idx == 1 or rcv_pkt_idx == 4) {  // rx block 0 xor block 1 
                                        for (int j = 0; j < len_block; j++) {
                                                deco_pkt[(2 * len_block) + j] = deco_pkt[(0 * len_block) + j] ^ buffer[0][j] ^ buffer[1][j];
                                                deco_pkt[(3 * len_block) + j] = deco_pkt[(0 * len_block) + j] ^ buffer[1][j];
                                        }
                                } else if (rcv_pkt_idx == 2 or rcv_pkt_idx == 8) { // rx block 0 xor block 2                         
                                        for (int j = 0; j < len_block; j++) {
                                                deco_pkt[(3 * len_block) + j] = deco_pkt[(2 * len_block) + j] ^ buffer[0][j];
                                                deco_pkt[(1 * len_block) + j] = deco_pkt[(0 * len_block) + j] ^ buffer[2][j];
                                        }
                                } else if (rcv_pkt_idx == 3 or rcv_pkt_idx == 12) { // rx block 0 xor block 3
                                         for (int j = 0; j < len_block; j++) {
                                                deco_pkt[(2 * len_block) + j] = deco_pkt[(3 * len_block) + j] ^ buffer[0][j];
                                                deco_pkt[(1 * len_block) + j] = deco_pkt[(2 * len_block) + j] ^ buffer[3][j];
                                        }
                                } else if (rcv_pkt_idx == 6 or rcv_pkt_idx == 9) { // rx block 1 xor block 2
                                       for (int j = 0; j < len_block; j++) {
                                                deco_pkt[(3 * len_block) + j] = deco_pkt[(1 * len_block) + j] ^ buffer[2][j] ^ buffer[1][j];
                                                deco_pkt[(0 * len_block) + j] = deco_pkt[(1 * len_block) + j] ^ buffer[2][j];
                                        }
                                } else if (rcv_pkt_idx == 7 or rcv_pkt_idx == 13) { // rx block 1 xor block 3
                                        for (int j = 0; j < len_block; j++) {
                                                deco_pkt[(0 * len_block) + j] = deco_pkt[(3 * len_block) + j] ^ buffer[1][j];
                                                deco_pkt[(2 * len_block) + j] = deco_pkt[(1 * len_block) + j] ^ buffer[3][j];
                                        }
                                } else if (rcv_pkt_idx == 11 or rcv_pkt_idx == 14) { // rx block 2 xor block 3 
                                        for (int j = 0; j < len_block; j++) {
                                                deco_pkt[(1 * len_block) + j] = deco_pkt[(2 * len_block) + j] ^ buffer[3][j];
                                                deco_pkt[(0 * len_block) + j] = deco_pkt[(2 * len_block) + j] ^ buffer[3][j] ^ buffer[2][j];
                                        }
                                } else
                                        std::cout << "Big problem with the idx" << std::endl;

                                std::cout << "Decoded   Pkt" << std::endl;
                                for (auto n : deco_pkt)
                                        std::cout  << std::hex << int(n);
                                std::cout << std::endl;

                                std::cout << "Original Pkt" << std::endl;
                                for (auto n : pkt) 
                                        std::cout << std::hex << int(n);
                                std::cout << std::endl;

                                if (deco_pkt == pkt) {
                                    std::cout << "Decoded" << std::endl;
                                    return 0;
                                } else {
                                    std::cout << "Error Decoded" << std::endl;
                                    return 1;
                                }
                        }
                }

        } else {
                std::cout << "Can't decode the pkt" << std::endl;
        }
        return 0;
}
