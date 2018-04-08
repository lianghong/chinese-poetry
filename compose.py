#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tensorflow as tf
import os
import random
import re
import time
import boto3
import tarfile
from data_utils import TextConverter
from model import CharRNN

FLAGS = tf.flags.FLAGS
tf.flags.DEFINE_integer('lstm_size', 128, 'size of hidden state of lstm')
tf.flags.DEFINE_integer('num_layers', 2, 'number of lstm layers')
tf.flags.DEFINE_boolean('use_embedding', True, 'whether to use embedding')
tf.flags.DEFINE_integer('embedding_size', 128, 'size of embedding')
tf.flags.DEFINE_string('converter_path', '/tmp/chinese_poetry/converter.pkl', 'model/name/converter.pkl')
tf.flags.DEFINE_string('checkpoint_path', '/tmp/chinese_poetry', 'checkpoint path')
# tf.flags.DEFINE_string('start_string', '', 'use this string to start generating')
tf.flags.DEFINE_integer('max_length', 2000, 'max length to generate')
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

noItemMsg = "此刻江郎才已尽， 翻来覆去肠已穿。 为求新诗心不老， 劝君再把牛刀试。"
tmpPath = "/tmp/chinese_poetry/"
modelFile = "chinese_poetry_model.tgz"
commaChar = "，"
fullStopChar = "。"

def downloadModel():
    if not os.path.exists(tmpPath):
        os.makedirs(tmpPath)
    strBucket = "chinese-poetry"
    strKey = "chinese_poetry_model.tgz"
    strFile = tmpPath + modelFile
    if not os.path.exists(strFile):
        downloadFromS3(strBucket, strKey, strFile)
    if not os.path.exists(tmpPath + "converter.pkl"):
        file = tarfile.open(strFile, 'r:gz')
        file.extractall(tmpPath)

def downloadFromS3(strBucket, strKey, strFile):
    s3_client = boto3.client('s3')
    s3_client.download_file(strBucket, strKey, strFile)

def selectPoetry(text):
    retList = []
    lines = text.split("\n")
    for line in lines:
        if re.search(r"(\w{5,7}\s){3}\w{5,7}", line) is not None:
            retList.append(line)
    if len(retList) > 0:
        return addPunctuation((random.choice(retList)))
    else:
        return noItemMsg

def addPunctuation(text):
    lines = text.strip().split(" ")
    index = 0
    retList = []
    for line in lines:
        retList.append(line)
        if index % 2 == 0:
            retList.append(commaChar)
        else:
            retList.append(fullStopChar)
        index += 1
    return "".join(retList)

def composePotery():
    converter = TextConverter(filename=FLAGS.converter_path)
    if os.path.isdir(FLAGS.checkpoint_path):
        FLAGS.checkpoint_path =\
            tf.train.latest_checkpoint(FLAGS.checkpoint_path)

    model = CharRNN(converter.vocab_size, sampling=True,
                    lstm_size=FLAGS.lstm_size, num_layers=FLAGS.num_layers,
                    use_embedding=FLAGS.use_embedding,
                    embedding_size=FLAGS.embedding_size)
    model.load(FLAGS.checkpoint_path)

    start = []
    arr = model.sample(FLAGS.max_length, start, converter.vocab_size)
    rawText = converter.arr_to_text(arr)
    return(selectPoetry(rawText))


def lambda_handler(event, context):
    startTime = time.time()
    print(event)
    print(context)
    downloadModel()
    strResult = composePotery()
    print("Time cost is %d second(s)" % (time.time() - startTime))
    return strResult


if __name__ == '__main__':
    ret = lambda_handler(None, None)
    print(ret)

